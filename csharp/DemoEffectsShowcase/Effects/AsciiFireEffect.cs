using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class AsciiFireEffect : DemoSceneEffect
{
    // Ordered from visually "cold" (space/dots) to "hot" (dense glyphs).
    // Only glyphs already supported by SdlText are used.
    private const string Palette = "    ....::::----====++++1111LLLLGGGG8888";
    private static readonly string[] PaletteGlyphs = BuildGlyphCache();

    private readonly Random _random = new(1989);
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    private int _width;
    private int _height;
    private int _gridW;
    private int _gridH;
    private int[] _heat = [0];

    private float _speed = 1.0f;
    private float _intensity = 1.0f;
    private float _cooling = 1.0f;
    private int _fontScale = 2;
    private double _stepAccumulator;

    public AsciiFireEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 3.0f),
            EffectParameters.Float("intensity", "Intensity", () => _intensity, v => _intensity = v, 0.2f, 2.2f),
            EffectParameters.Float("cooling", "Cooling", () => _cooling, v => _cooling = v, 0.1f, 2.0f),
            EffectParameters.Float("font", "Font Size", () => _fontScale, v => SetFontScale(v), 1f, 4f)
        ];
    }

    public string Id => "ascii-fire";
    public string Name => "Ascii Fire";
    public string Description => "ASCII fire simulation with palette and per-character coloring.";
    public IReadOnlyList<string> Tags => ["ascii", "fire", "text", "simulation"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        Array.Fill(_heat, 0);
        _stepAccumulator = 0;
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
        RebuildGrid();
    }

    public void Update(double deltaSeconds)
    {
        // Run simulation in discrete steps.
        // Higher speed means more simulation steps per rendered frame.
        _stepAccumulator += deltaSeconds * _speed * 60.0;
        while (_stepAccumulator >= 1.0)
        {
            StepSimulation();
            _stepAccumulator -= 1.0;
        }
    }

    public void Render(IntPtr renderer)
    {
        var cellW = 6 * _fontScale;
        var cellH = 8 * _fontScale;
        var maxPalette = Palette.Length - 1;

        for (var y = 0; y < _gridH; y++)
        {
            for (var x = 0; x < _gridW; x++)
            {
                var heat = _heat[Index(x, y)];
                if (heat <= 0)
                {
                    continue;
                }

                // Convert heat (0..255) to a glyph index in the ASCII palette.
                var glyphIndex = heat * maxPalette / 255;
                var glyph = PaletteGlyphs[glyphIndex];
                var (r, g, b) = FireColor(heat);

                SdlText.Draw(renderer, glyph, x * cellW, y * cellH, _fontScale, r, g, b);
            }
        }
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;
    public void Dispose() { }

    private void StepSimulation()
    {
        if (_gridW < 2 || _gridH < 2)
        {
            return;
        }

        var bottomY = _gridH - 1;

        // Phase 1: seeding.
        // Add random hot cells on the bottom row (fire source).
        var seeds = Math.Max(1, (int)(_gridW * _intensity));
        for (var i = 0; i < seeds; i++)
        {
            var x = _random.Next(_gridW);
            _heat[Index(x, bottomY)] = _random.Next(140, 256);
        }

        // Phase 2: cooling.
        // Randomly zero some bottom cells to create gaps between flames.
        var cools = Math.Max(0, (int)(_gridW * _cooling));
        for (var i = 0; i < cools; i++)
        {
            var x = _random.Next(_gridW);
            _heat[Index(x, bottomY)] = 0;
        }

        // Phase 3: propagation.
        // Average each cell with neighbors from the row below.
        // Integer division naturally drops fractions, which cools the fire over height.
        for (var y = 0; y < _gridH - 1; y++)
        {
            for (var x = 0; x < _gridW; x++)
            {
                var xr = Math.Min(_gridW - 1, x + 1);
                var idx = Index(x, y);
                var avg = (
                    _heat[idx] +
                    _heat[Index(xr, y)] +
                    _heat[Index(x, y + 1)] +
                    _heat[Index(xr, y + 1)]) / 4;
                _heat[idx] = avg;
            }
        }
    }

    private void RebuildGrid()
    {
        var cellW = Math.Max(6, 6 * _fontScale);
        var cellH = Math.Max(8, 8 * _fontScale);
        _gridW = Math.Max(8, _width / cellW);
        _gridH = Math.Max(8, _height / cellH);
        _heat = new int[_gridW * _gridH];
    }

    private void SetFontScale(float value)
    {
        var newScale = Math.Clamp((int)MathF.Round(value), 1, 4);
        if (newScale == _fontScale)
        {
            return;
        }

        _fontScale = newScale;
        if (_width > 0 && _height > 0)
        {
            RebuildGrid();
        }
    }

    private int Index(int x, int y) => y * _gridW + x;

    private static string[] BuildGlyphCache()
    {
        var cache = new string[Palette.Length];
        for (var i = 0; i < Palette.Length; i++)
        {
            cache[i] = Palette[i].ToString();
        }

        return cache;
    }

    private static (byte r, byte g, byte b) FireColor(int heat)
    {
        var value = Math.Clamp(heat, 0, 255);
        if (value < 85)
        {
            return ((byte)(value * 3), 0, 0);
        }

        if (value < 170)
        {
            return (255, (byte)((value - 85) * 3), 0);
        }

        return (255, 255, (byte)((value - 170) * 3));
    }
}
