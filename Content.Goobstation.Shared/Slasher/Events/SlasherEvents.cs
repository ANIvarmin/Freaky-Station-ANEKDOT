using Content.Shared.Actions;
using Content.Shared.DoAfter;
using Robust.Shared.Serialization;

namespace Content.Goobstation.Shared.Slasher.Events;

[ByRefEvent]
public sealed partial class SlasherRegenerateEvent : InstantActionEvent;

[ByRefEvent]
public sealed partial class SlasherMassacreEvent : InstantActionEvent;

[ByRefEvent]
public sealed partial class SlasherPossessionEvent : EntityTargetActionEvent;

[ByRefEvent]
public sealed partial class ToggleBloodTrailEvent : InstantActionEvent;

[ByRefEvent]
public sealed partial class SlasherSoulStealEvent : EntityTargetActionEvent;

[ByRefEvent]
public sealed partial class SlasherStaggerAreaEvent : InstantActionEvent;

[ByRefEvent]
public sealed partial class SlasherSummonMacheteEvent : InstantActionEvent;

[ByRefEvent]
public sealed partial class SlasherSummonMeatSpikeEvent : InstantActionEvent;

[Serializable, NetSerializable]
public sealed partial class SlasherSoulStealDoAfterEvent : SimpleDoAfterEvent;

[ByRefEvent]
public sealed partial class SlasherIncorporealizeEvent : InstantActionEvent;

[ByRefEvent]
public sealed partial class SlasherCorporealizeEvent : InstantActionEvent;

[Serializable, NetSerializable]
public sealed partial class SlasherIncorporealizeDoAfterEvent : SimpleDoAfterEvent;

[ByRefEvent]
public record struct SlasherIncorporealObserverCheckEvent
{
    public NetEntity Slasher;
    public float Range;
    public bool Cancelled;

    public SlasherIncorporealObserverCheckEvent(NetEntity slasher, float range)
    {
        Slasher = slasher;
        Range = range;
    }
}

[ByRefEvent]
public record struct SlasherIncorporealCameraCheckEvent
{
    public NetEntity Slasher;
    public float Range;
    public bool Cancelled;

    public SlasherIncorporealCameraCheckEvent(NetEntity slasher, float range)
    {
        Slasher = slasher;
        Range = range;
    }
}

[ByRefEvent]
public record struct SlasherIncorporealEnteredEvent;
