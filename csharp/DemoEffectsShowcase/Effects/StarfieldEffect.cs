using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class StarfieldEffect : DemoSceneEffect
{
    private readonly Random _random = new(1337);
    private Star[] _stars = [];
    private int _width;
    private int _height;
    private const int StarCount = 420;
    private const float MaxDepth = 24f;
    private float _speed = 1.0f;
    private float _fovScale = 0.7f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public StarfieldEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.1f, 4.0f),
            EffectParameters.Float("fov", "FOV", () => _fovScale, v => _fovScale = v, 0.3f, 1.4f)
        ];
    }

    public string Id => "starfield";
    public string Name => "Starfield";
    public string Description => "3D stars flying forward.";
    public IReadOnlyList<string> Tags => ["star", "3d", "space"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        _stars = new Star[StarCount];
        for (var i = 0; i < _stars.Length; i++)
        {
            _stars[i] = NewStar();
        }
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds)
    {
        var speed = (float)(deltaSeconds * 9.5 * _speed);
        for (var i = 0; i < _stars.Length; i++)
        {
            var star = _stars[i];
            star.Z -= speed;
            if (star.Z <= 0.08f)
            {
                _stars[i] = NewStar();
                continue;
            }

            _stars[i] = star;
        }
    }

    public void Render(IntPtr renderer)
    {
        var centerX = _width * 0.5f;
        var centerY = _height * 0.5f;
        var fov = _width * _fovScale;

        for (var i = 0; i < _stars.Length; i++)
        {
            var star = _stars[i];
            var screenX = centerX + (star.X / star.Z) * fov;
            var screenY = centerY + (star.Y / star.Z) * fov;
            if (screenX < 0 || screenY < 0 || screenX >= _width || screenY >= _height)
            {
                _stars[i] = NewStar();
                continue;
            }

            var brightness = (byte)Math.Clamp(255 - (star.Z / MaxDepth) * 220, 40, 255);
            SdlFx.FilledCircle(renderer, (int)screenX, (int)screenY, 1, brightness, brightness, brightness);
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    private Star NewStar() =>
        new(
            (float)(_random.NextDouble() * 2.0 - 1.0) * _width * 0.8f,
            (float)(_random.NextDouble() * 2.0 - 1.0) * _height * 0.8f,
            0.2f + (float)_random.NextDouble() * MaxDepth);

    private struct Star(float x, float y, float z)
    {
        public float X = x;
        public float Y = y;
        public float Z = z;
    }
}
