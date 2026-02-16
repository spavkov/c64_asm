namespace DemoEffectsShowcase.Core;

public interface DemoSceneEffect : IDisposable
{
    string Id { get; }
    string Name { get; }
    string Description { get; }
    IReadOnlyList<string> Tags { get; }

    void Initialize(in EffectInitContext context);
    void Resize(int width, int height);
    void Update(double deltaSeconds);
    void Render(IntPtr renderer);
    IReadOnlyList<EffectParameterDefinition> GetParameters() => [];
}
