using Content.Goobstation.Maths.FixedPoint;
using Content.Shared.Chat.Prototypes;
using Content.Shared.Speech;
using Robust.Shared.Audio;
using Robust.Shared.GameStates;
using Robust.Shared.Prototypes;

namespace Content.Shared._Shitcode.Heretic.Components;

[RegisterComponent, NetworkedComponent, AutoGenerateComponentState]
public sealed partial class ShadowCloakedComponent : Component
{
    [ViewVariables]
    public bool WasVisible = true;

    [DataField]
    public EntProtoId ShadowCloakEntity = "ShadowCloakEntity";

    [DataField, AutoNetworkedField]
    public ProtoId<EmoteSoundsPrototype>? EmoteSounds = "ShadowCloak";

    [DataField, AutoNetworkedField]
    public ProtoId<SpeechSoundsPrototype>? SpeechSounds = "ShadowCloak";

    [DataField, AutoNetworkedField]
    public ProtoId<SpeechVerbPrototype> SpeechVerb = "Hiss";

    [DataField, AutoNetworkedField]
    public FixedPoint2 SustainedDamage;

    [DataField, AutoNetworkedField]
    public FixedPoint2 DamageBeforeReveal = 25;

    [DataField, AutoNetworkedField]
    public bool DebuffOnEarlyReveal;

    [DataField, AutoNetworkedField]
    public TimeSpan KnockdownTime = TimeSpan.FromSeconds(0.5f);

    [DataField, AutoNetworkedField]
    public (float walk, float sprint) EarlyRemoveMoveSpeedModifiers = (0.5f, 0.5f);

    [DataField, AutoNetworkedField]
    public TimeSpan SlowdownTime = TimeSpan.FromSeconds(10f);

    [DataField, AutoNetworkedField]
    public TimeSpan ForceRevealCooldown = TimeSpan.FromMinutes(2f);

    [DataField, AutoNetworkedField]
    public float DoAfterSlowdown = 3f;

    [DataField, AutoNetworkedField]
    public (float walk, float sprint) MoveSpeedModifiers = (0.6f, 0.6f);

    [DataField, AutoNetworkedField]
    public TimeSpan RevealCooldown = TimeSpan.FromMinutes(1f);

    [DataField, AutoNetworkedField]
    public SoundSpecifier? Sound;

    [DataField, AutoNetworkedField]
    public string ShadowCloakAlert = "ShadowCloakStatusEffect";}
