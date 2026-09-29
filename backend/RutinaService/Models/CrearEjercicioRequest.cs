using System.Text.Json.Serialization;

namespace RutinaService.Models;

public class CrearEjercicioRequest
{
    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

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

    // Distingue un campo omitido de un null explícito en el JSON.
    [JsonIgnore]
    public bool ImagenUrlEspecificada { get; private set; }
}
