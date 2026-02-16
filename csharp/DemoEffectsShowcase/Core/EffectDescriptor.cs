namespace DemoEffectsShowcase.Core;

public sealed class EffectDescriptor
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public string Description { get; init; } = string.Empty;
    public string Category { get; init; } = "General";
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();
    public required Func<DemoSceneEffect> Factory { get; init; }
}
