namespace GymManagement.api.Services;

public class NotificacionWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<NotificacionWorker> _logger;
    private readonly bool _habilitado;
    private readonly int _dias;
    private readonly TimeSpan _intervalo;

    public NotificacionWorker(
        IServiceScopeFactory scopeFactory,
        IConfiguration configuration,
        ILogger<NotificacionWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;

        _habilitado = configuration.GetValue(
            "Notificaciones:GeneracionHabilitada", true);

        _dias = configuration.GetValue(
            "Notificaciones:DiasAnticipacion", 7);

        var minutos = configuration.GetValue(
            "Notificaciones:IntervaloMinutos", 60);

        if (_dias < 0 || _dias > 365)
            throw new InvalidOperationException(
                "DiasAnticipacion debe estar entre 0 y 365.");

        if (minutos < 1 || minutos > 1440)
            throw new InvalidOperationException(
                "IntervaloMinutos debe estar entre 1 y 1440.");

        _intervalo = TimeSpan.FromMinutes(minutos);
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        if (!_habilitado)
        {
            _logger.LogInformation(
                "Generación periódica de avisos desactivada.");

            return;
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope =
                    _scopeFactory.CreateAsyncScope();

                var service = scope.ServiceProvider
                    .GetRequiredService<NotificacionService>();

                var creadas =
                    await service.GenerarAvisosVencimiento(
                        _dias,
                        stoppingToken);

                _logger.LogInformation(
                    "Generación de avisos completada. " +
                    "Anticipación: {Dias} días. Creadas: {Creadas}.",
                    _dias,
                    creadas);
            }
            catch (OperationCanceledException)
                when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Error al generar avisos. " +
                    "Se reintentará en el siguiente intervalo.");
            }

            try
            {
                await Task.Delay(_intervalo, stoppingToken);
            }
            catch (OperationCanceledException)
                when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
        }
    }
}