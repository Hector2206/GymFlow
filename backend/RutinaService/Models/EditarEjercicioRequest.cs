using System.Text.Json.Serialization;

namespace RutinaService.Models;

public class EditarEjercicioRequest
{
    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public bool? Estado { get; set; }

    private string? imagenUrl;

    public string? ImagenUrl
    {
        get => imagenUrl;
        set
        {
            imagenUrl = value;
            ImagenUrlEspecificada = true;
        }
    }

    [JsonIgnore]
    public bool ImagenUrlEspecificada { get; private set; }
}