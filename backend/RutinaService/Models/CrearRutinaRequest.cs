namespace RutinaService.Models;

public class CrearRutinaRequest
{
    public int IdCliente { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public List<DiaRutinaRequest> Dias { get; set; } = [];
}

public class DiaRutinaRequest
{
    public string Dia { get; set; } = string.Empty;

    public List<EjercicioRutinaRequest> Ejercicios { get; set; } = [];
}

public class EjercicioRutinaRequest
{
    public int IdEjercicio { get; set; }

    public int Series { get; set; }

    public int Repeticiones { get; set; }

    public int Orden { get; set; }
}
