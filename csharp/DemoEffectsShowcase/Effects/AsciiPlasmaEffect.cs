using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class AsciiPlasmaEffect : DemoSceneEffect
{
    // Palette uses glyphs supported by SdlText, ordered from sparse to dense.
    // inspired from here: https://www.asciiart.eu/animations/ascii-plasma
    private const string AsciiPalette = "   ...::--==++11LLGG88QQWW";
    private static readonly string[] GlyphCache = BuildGlyphCache();

    private int _width;
    private int _height;
    private double _time;

    private float _speed = 1.0f;
    private float _zoom = 1.0f;
    private float _blend = 0.5f;
    private int _patternIndex;
    private int _fontScale = 2;
    private static readonly string[] PatternOptions =
    [
        "Classic",
        "Vortex",
        "Interference",
        "Diamond",
        "Tunnel",
        "Ripple",
        "Metaballs",
        "Moire",
        "Checkerboard",
        "Waves",
        "Warp",
        "Kaleidoscope",
        "Matrix",
        "Spiral",
        "Pulse"
    ];

    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public AsciiPlasmaEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.1f, 4.0f),
            EffectParameters.Float("zoom", "Zoom", () => _zoom, v => _zoom = v, 0.4f, 2.5f),
            EffectParameters.Float("blend", "Blend", () => _blend, v => _blend = v, 0.0f, 1.0f),
            EffectParameters.Dropdown("pattern", "Pattern", PatternOptions, () => _patternIndex, SetPattern),
            EffectParameters.Float("font", "Font Size", () => _fontScale, v => SetFontScale(v), 1f, 4f)
        ];
    }

    public string Id => "ascii-plasma";
    public string Name => "Ascii Plasma";
    public string Description => "Animated ASCII plasma with switchable patterns and wave blending.";
    public IReadOnlyList<string> Tags => ["ascii", "plasma", "text", "waves"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        _time = 0;
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        var cellW = 6 * _fontScale;
        var cellH = 8 * _fontScale;
        var cols = Math.Max(8, _width / cellW);
        var rows = Math.Max(8, _height / cellH);
        var t = (float)_time;

        for (var y = 0; y < rows; y++)
        {
            for (var x = 0; x < cols; x++)
            {
                // Convert grid coordinates to centered UV so equations are resolution independent.
                var u = (x - cols * 0.5f) / (MathF.Max(1, cols) * 0.35f) * _zoom;
                var v = (y - rows * 0.5f) / (MathF.Max(1, rows) * 0.35f) * _zoom;

                // Evaluate two pattern functions and blend them.
                // "Pattern" selects the base function (0,1,2), "Blend" mixes to the next one.
                var basePattern = _patternIndex;
                var nextPattern = (basePattern + 1) % 3;
                var a = PatternValue(basePattern, u, v, t);
                var b = PatternValue(nextPattern, u, v, t);
                var plasma = Math.Clamp(a + (b - a) * _blend, -2f, 2f);

                // Convert plasma [-2..2] into [0..1], then map to glyph and heat-map color.
                var normalized = (plasma + 2f) * 0.25f;
                var glyphIndex = (int)Math.Clamp(normalized * (AsciiPalette.Length - 1), 0, AsciiPalette.Length - 1);
                var glyph = GlyphCache[glyphIndex];
                var (r, g, bl) = HeatMap(normalized);
                SdlText.Draw(renderer, glyph, x * cellW, y * cellH, _fontScale, r, g, bl);
            }
        }
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;
    public void Dispose() { }

    private static float PatternValue(int pattern, float u, float v, float t)
    {
        var r = MathF.Sqrt(u * u + v * v);
        var a = MathF.Atan2(v, u);
        return pattern switch
        {
            0 =>
                // Classic layered plasma.
                MathF.Sin(u * 2.1f + t * 1.2f) +
                MathF.Sin(v * 1.6f - t) +
                MathF.Sin((u + v) * 1.3f + t * 0.7f),
            1 =>
                // Vortex spiral around the origin.
                MathF.Sin(a * 5.0f + r * 3.0f - t * 1.4f) +
                MathF.Cos(r * 4.0f - t * 0.8f),
            2 =>
                // Circular wave interference.
                MathF.Sin(MathF.Sqrt((u - 0.8f) * (u - 0.8f) + (v + 0.4f) * (v + 0.4f)) * 5f - t) +
                MathF.Sin(MathF.Sqrt((u + 0.7f) * (u + 0.7f) + (v - 0.5f) * (v - 0.5f)) * 4.5f + t * 1.1f),
            3 =>
                // Manhattan-distance diamonds.
                MathF.Sin((MathF.Abs(u) + MathF.Abs(v)) * 4.0f - t * 1.3f) +
                MathF.Cos((u - v) * 2.0f + t * 0.7f),
            4 =>
                // Tunnel zoom look.
                MathF.Sin(r * 8.0f - t * 2.4f) +
                MathF.Cos(a * 4.0f + t * 0.6f),
            5 =>
                // Ripple from center.
                MathF.Sin(r * 10.0f - t * 3.0f) *
                MathF.Exp(-r * 0.25f) * 2.0f,
            6 =>
                // Soft metaball-like blobs.
                1.6f / (0.35f + (u + MathF.Sin(t * 0.9f) * 0.7f) * (u + MathF.Sin(t * 0.9f) * 0.7f) + (v + MathF.Cos(t * 1.1f) * 0.6f) * (v + MathF.Cos(t * 1.1f) * 0.6f)) +
                1.5f / (0.35f + (u - MathF.Cos(t * 1.0f) * 0.8f) * (u - MathF.Cos(t * 1.0f) * 0.8f) + (v - MathF.Sin(t * 0.8f) * 0.7f) * (v - MathF.Sin(t * 0.8f) * 0.7f)) - 2.2f,
            7 =>
                // Moire overlap pattern.
                MathF.Sin((u * u + v * v) * 6.0f - t * 1.1f) +
                MathF.Sin((u * 3.0f + v * 2.0f) + t * 0.9f),
            8 =>
                // Checkerboard with wave phase.
                MathF.Sin(u * 5.2f + t) * MathF.Sin(v * 5.2f - t * 1.1f) * 2.0f,
            9 =>
                // Horizontal retro waves.
                MathF.Sin(v * 4.2f + t * 1.4f) +
                0.8f * MathF.Sin(v * 8.5f - t * 0.9f + MathF.Sin(u * 1.5f)),
            10 =>
                // Warp speed streaks.
                MathF.Sin(a * 14.0f + r * 0.5f - t * 1.6f) +
                MathF.Cos(1.0f / MathF.Max(0.08f, r) - t * 0.8f),
            11 =>
                // Kaleidoscope reflections.
                MathF.Sin(MathF.Abs(MathF.Cos(a * 4.0f)) * r * 7.0f - t * 1.2f) +
                MathF.Cos((u * u - v * v) * 3.0f + t * 0.6f),
            12 =>
                // Matrix-like vertical drift.
                MathF.Sin(v * 7.0f + t * 2.0f + MathF.Sin(u * 2.0f) * 1.5f) +
                MathF.Sin(v * 2.0f - t * 0.7f),
            13 =>
                // Archimedean spiral style.
                MathF.Sin(a * 6.0f + r * 9.0f - t * 2.0f) +
                MathF.Cos(a * 3.0f - t * 0.7f),
            _ =>
                // Pulse rings.
                MathF.Sin(r * 12.0f - t * 3.0f) +
                MathF.Sin(r * 4.0f - t * 0.8f)
        };
    }

    private void SetFontScale(float value)
    {
        _fontScale = Math.Clamp((int)MathF.Round(value), 1, 4);
    }

    private void SetPattern(int value)
    {
        _patternIndex = Math.Clamp(value, 0, PatternOptions.Length - 1);
    }

    private static string[] BuildGlyphCache()
    {
        var cache = new string[AsciiPalette.Length];
        for (var i = 0; i < AsciiPalette.Length; i++)
        {
            cache[i] = AsciiPalette[i].ToString();
        }

        return cache;
    }

    private static (byte r, byte g, byte b) HeatMap(float t)
    {
        // Piecewise heat-map gradient:
        // blue -> cyan -> yellow -> red -> white.
        t = Math.Clamp(t, 0f, 1f);
        if (t < 0.25f)
        {
            var k = t / 0.25f;
            return ((byte)(k * 80), (byte)(k * 180), (byte)(80 + k * 175));
        }

        if (t < 0.5f)
        {
            var k = (t - 0.25f) / 0.25f;
            return ((byte)(80 + k * 175), (byte)(180 + k * 75), (byte)(255 - k * 255));
        }

        if (t < 0.8f)
        {
            var k = (t - 0.5f) / 0.3f;
            return (255, (byte)(255 - k * 200), 0);
        }

        var w = (t - 0.8f) / 0.2f;
        return (255, (byte)(55 + w * 200), (byte)(w * 200));
    }
}
