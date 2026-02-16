using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class MeatballsEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1.1f;
    private float _threshold = 0.9f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const int Step = 6;

    public MeatballsEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 3.0f),
            EffectParameters.Float("threshold", "Blob Threshold", () => _threshold, v => _threshold = v, 0.3f, 1.8f)
        ];
    }

    public string Id => "meatballs";
    public string Name => "Meatballs";
    public string Description => "Metaballs/meatballs scalar-field effect.";
    public IReadOnlyList<string> Tags => ["metaballs", "meatballs", "blob"];

    public void Initialize(in EffectInitContext context) => Resize(context.Width, context.Height);
    public void Resize(int width, int height) { _width = Math.Max(1, width); _height = Math.Max(1, height); }
    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        var balls = new (float X, float Y, float R)[]
        {
            (_width * (0.25f + 0.15f * MathF.Sin((float)_time * 1.2f)), _height * (0.40f + 0.25f * MathF.Sin((float)_time * 1.6f)), _width * 0.16f),
            (_width * (0.55f + 0.18f * MathF.Sin((float)_time * 1.1f + 1.4f)), _height * (0.45f + 0.22f * MathF.Sin((float)_time * 1.4f + 2.1f)), _width * 0.14f),
            (_width * (0.72f + 0.16f * MathF.Sin((float)_time * 0.9f + 3.3f)), _height * (0.55f + 0.21f * MathF.Sin((float)_time * 1.7f + 0.7f)), _width * 0.15f)
        };

        for (var y = 0; y < _height; y += Step)
        for (var x = 0; x < _width; x += Step)
        {
            float field = 0f;
            foreach (var b in balls)
            {
                var dx = x - b.X;
                var dy = y - b.Y;
                var d2 = dx * dx + dy * dy + 1f;
                field += (b.R * b.R) / d2;
            }

            if (field < _threshold) continue;
            var t = Math.Clamp((field - _threshold) / 1.8f, 0f, 1f);
            SdlFx.FillRect(renderer, x, y, Step, Step, (byte)(80 + t * 150), (byte)(30 + t * 120), (byte)(140 + t * 100), (byte)(130 + t * 100));
        }
    }

    public void Dispose() { }
    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;
}
