using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class AsciiDonutEffect : DemoSceneEffect
{
    // Inspired by: https://www.asciiart.eu/animations/ascii-spinning-donut
    // This is an original C# implementation for this project.
    private static readonly string[] CharsetOptions = ["Classic", "Blocks", "Simple", "Detailed"];
    private static readonly string[] ColorModeOptions = ["None", "Fire", "Cool", "Rainbow", "Matrix", "Sunset"];
    private static readonly string[] ToggleOptions = ["Off", "On"];

    private static readonly string[] ClassicChars = BuildGlyphCache(" .:-=+LQ8");
    private static readonly string[] BlocksChars = BuildGlyphCache("░░░░░░░▒▒▒▒▒▒▒▓▓");
    private static readonly string[] SimpleChars = BuildGlyphCache(" .:+=8");
    private static readonly string[] DetailedChars = BuildGlyphCache("  ..::--==++11LLGGQQ88WW");

    private int _width;
    private int _height;
    private double _time;
    private float _angleX;
    private float _angleY;

    private float _speedX = 2f;
    private float _speedY = 1f;
    private float _size = 75f;
    private float _thickness = 50f;
    private float _lightAngle = 45f;
    private float _lightHeight = 45f;
    private int _charsetIndex;
    private int _colorModeIndex;
    private int _autoRotateIndex = 1;
    private int _wobbleIndex;
    private int _fontScale = 2;

    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public AsciiDonutEffect()
    {
        _parameters =
        [
            EffectParameters.Dropdown("auto", "Auto Rotate", ToggleOptions, () => _autoRotateIndex, v => _autoRotateIndex = Math.Clamp(v, 0, 1)),
            EffectParameters.Dropdown("wobble", "Wobble", ToggleOptions, () => _wobbleIndex, v => _wobbleIndex = Math.Clamp(v, 0, 1)),
            EffectParameters.Float("speedx", "Rotation X", () => _speedX, v => _speedX = v, 0f, 10f),
            EffectParameters.Float("speedy", "Rotation Y", () => _speedY, v => _speedY = v, 0f, 10f),
            EffectParameters.Float("size", "Size", () => _size, v => _size = v, 10f, 200f),
            EffectParameters.Float("thickness", "Thickness", () => _thickness, v => _thickness = v, 10f, 80f),
            EffectParameters.Float("light-angle", "Light Angle", () => _lightAngle, v => _lightAngle = v, 0f, 360f),
            EffectParameters.Float("light-height", "Light Height", () => _lightHeight, v => _lightHeight = v, -90f, 90f),
            EffectParameters.Dropdown("charset", "Characters", CharsetOptions, () => _charsetIndex, v => _charsetIndex = Math.Clamp(v, 0, CharsetOptions.Length - 1)),
            EffectParameters.Dropdown("color", "Color", ColorModeOptions, () => _colorModeIndex, v => _colorModeIndex = Math.Clamp(v, 0, ColorModeOptions.Length - 1)),
            EffectParameters.Float("font", "Font Size", () => _fontScale, v => _fontScale = Math.Clamp((int)MathF.Round(v), 1, 4), 1f, 4f)
        ];
    }

    public string Id => "ascii-donut";
    public string Name => "Ascii Donut";
    public string Description => "Rotating ASCII torus with shading, color modes, and character sets.";
    public IReadOnlyList<string> Tags => ["ascii", "donut", "torus", "3d"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        _time = 0;
        _angleX = 0;
        _angleY = 0;
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds)
    {
        _time += deltaSeconds;
        if (_autoRotateIndex == 1)
        {
            _angleX += (float)(deltaSeconds * _speedX);
            _angleY += (float)(deltaSeconds * _speedY);
        }
    }

    public void Render(IntPtr renderer)
    {
        var chars = GetCharset();
        var cellW = 6 * _fontScale;
        var cellH = 8 * _fontScale;
        var cols = Math.Max(12, _width / cellW);
        var rows = Math.Max(10, _height / cellH);
        var count = cols * rows;

        var zBuffer = new float[count];
        var glyphBuffer = new int[count];
        var lightBuffer = new float[count];
        Array.Fill(zBuffer, float.NegativeInfinity);
        Array.Fill(glyphBuffer, -1);

        // Donut radii derived from UI sliders.
        var majorRadius = _size / 55f;
        var minorRadius = _thickness / 120f;
        var cameraDistance = 4.4f + majorRadius * 0.6f;
        var projection = cols * 1.8f;

        var wobble = _wobbleIndex == 1 ? 0.18f * MathF.Sin((float)_time * 1.6f) : 0f;
        var rotX = _angleX + wobble;
        var rotY = _angleY + wobble * 0.6f;

        var light = BuildLightDirection(_lightAngle, _lightHeight);

        // Parametric torus: two angles build one ring (theta) around another ring (phi).
        // For each point we rotate, project to screen, and keep the nearest sample per cell.
        for (var theta = 0f; theta < MathF.Tau; theta += 0.22f)
        {
            var cosT = MathF.Cos(theta);
            var sinT = MathF.Sin(theta);

            for (var phi = 0f; phi < MathF.Tau; phi += 0.08f)
            {
                var cosP = MathF.Cos(phi);
                var sinP = MathF.Sin(phi);

                var ring = majorRadius + minorRadius * cosT;
                var point = new Vector3(ring * cosP, ring * sinP, minorRadius * sinT);
                var normal = Vector3.Normalize(new Vector3(cosT * cosP, cosT * sinP, sinT));

                var rp = RotateXY(point, rotX, rotY);
                var rn = Vector3.Normalize(RotateXY(normal, rotX, rotY));

                var depth = rp.Z + cameraDistance;
                if (depth <= 0.05f)
                {
                    continue;
                }

                var invDepth = 1f / depth;
                var sx = (int)(cols * 0.5f + projection * invDepth * rp.X);
                var sy = (int)(rows * 0.5f - projection * invDepth * rp.Y);
                if (sx < 0 || sx >= cols || sy < 0 || sy >= rows)
                {
                    continue;
                }

                var idx = sy * cols + sx;
                if (invDepth <= zBuffer[idx])
                {
                    continue;
                }

                var lum = MathF.Max(0f, Vector3.Dot(rn, light));
                var glyphIndex = Math.Clamp((int)(lum * (chars.Length - 1)), 0, chars.Length - 1);
                zBuffer[idx] = invDepth;
                glyphBuffer[idx] = glyphIndex;
                lightBuffer[idx] = lum;
            }
        }

        for (var y = 0; y < rows; y++)
        {
            for (var x = 0; x < cols; x++)
            {
                var idx = y * cols + x;
                var gi = glyphBuffer[idx];
                if (gi < 0)
                {
                    continue;
                }

                var shade = lightBuffer[idx];
                var (r, g, b) = GetColor(shade, _colorModeIndex);
                SdlText.Draw(renderer, chars[gi], x * cellW, y * cellH, _fontScale, r, g, b);
            }
        }
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;
    public void Dispose() { }

    private static Vector3 RotateXY(Vector3 v, float ax, float ay)
    {
        // Rotate around X first, then Y.
        var cx = MathF.Cos(ax);
        var sx = MathF.Sin(ax);
        var cy = MathF.Cos(ay);
        var sy = MathF.Sin(ay);

        var y1 = v.Y * cx - v.Z * sx;
        var z1 = v.Y * sx + v.Z * cx;
        var x2 = v.X * cy + z1 * sy;
        var z2 = -v.X * sy + z1 * cy;
        return new Vector3(x2, y1, z2);
    }

    private static Vector3 BuildLightDirection(float angleDeg, float heightDeg)
    {
        var az = angleDeg * MathF.PI / 180f;
        var el = heightDeg * MathF.PI / 180f;
        var c = MathF.Cos(el);
        return Vector3.Normalize(new Vector3(MathF.Cos(az) * c, MathF.Sin(el), MathF.Sin(az) * c));
    }

    private string[] GetCharset()
    {
        return _charsetIndex switch
        {
            1 => BlocksChars,
            2 => SimpleChars,
            3 => DetailedChars,
            _ => ClassicChars
        };
    }

    private static (byte r, byte g, byte b) GetColor(float t, int mode)
    {
        t = Math.Clamp(t, 0f, 1f);
        return mode switch
        {
            1 => ((byte)(120 + t * 135), (byte)(40 + t * 160), (byte)(t * 90)), // Fire
            2 => ((byte)(30 + t * 120), (byte)(120 + t * 120), (byte)(180 + t * 75)), // Cool
            3 => Rainbow(t),
            4 => ((byte)(t * 80), (byte)(120 + t * 135), (byte)(t * 80)), // Matrix
            5 => ((byte)(180 + t * 75), (byte)(80 + t * 120), (byte)(60 + t * 80)), // Sunset
            _ => ((byte)(40 + t * 215), (byte)(40 + t * 215), (byte)(40 + t * 215))
        };
    }

    private static (byte r, byte g, byte b) Rainbow(float t)
    {
        var r = 0.5f + 0.5f * MathF.Sin(6.28f * (t + 0.00f));
        var g = 0.5f + 0.5f * MathF.Sin(6.28f * (t + 0.33f));
        var b = 0.5f + 0.5f * MathF.Sin(6.28f * (t + 0.66f));
        return ((byte)(r * 255), (byte)(g * 255), (byte)(b * 255));
    }

    private static string[] BuildGlyphCache(string palette)
    {
        var cache = new string[palette.Length];
        for (var i = 0; i < palette.Length; i++)
        {
            cache[i] = palette[i].ToString();
        }

        return cache;
    }
}
