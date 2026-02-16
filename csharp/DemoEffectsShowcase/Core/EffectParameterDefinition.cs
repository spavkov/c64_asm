using System.Numerics;

namespace DemoEffectsShowcase.Core;

public enum EffectParameterKind
{
    Float,
    Color3
}

public sealed class EffectParameterDefinition
{
    public required string Key { get; init; }
    public required string Label { get; init; }
    public required EffectParameterKind Kind { get; init; }
    public float Min { get; init; }
    public float Max { get; init; }
    public required Func<float> GetFloat { get; init; }
    public required Action<float> SetFloat { get; init; }
    public required Func<Vector3> GetColor3 { get; init; }
    public required Action<Vector3> SetColor3 { get; init; }
}

public static class EffectParameters
{
    public static EffectParameterDefinition Float(
        string key,
        string label,
        Func<float> getter,
        Action<float> setter,
        float min,
        float max) =>
        new()
        {
            Key = key,
            Label = label,
            Kind = EffectParameterKind.Float,
            Min = min,
            Max = max,
            GetFloat = getter,
            SetFloat = setter,
            GetColor3 = static () => Vector3.One,
            SetColor3 = static _ => { }
        };

    public static EffectParameterDefinition Color3(
        string key,
        string label,
        Func<Vector3> getter,
        Action<Vector3> setter) =>
        new()
        {
            Key = key,
            Label = label,
            Kind = EffectParameterKind.Color3,
            Min = 0,
            Max = 1,
            GetFloat = static () => 0,
            SetFloat = static _ => { },
            GetColor3 = getter,
            SetColor3 = setter
        };
}
