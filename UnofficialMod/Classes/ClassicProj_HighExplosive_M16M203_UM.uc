//================================================
// ClassicProj_HighExplosive_M16M203_UM
//================================================
// Modified Classic Mode M203 grenade for Unofficial Mod
//================================================
// (c) 2019 "Insert Name Here"
//================================================
class ClassicProj_HighExplosive_M16M203_UM extends KFProj_HighExplosive_M16M203;

// Just copy/paste the defaultproperties
defaultproperties
{
    Speed=8000
    MaxSpeed=8000
    TerminalVelocity=8000
    LifeSpan=+10.0f

    // explosion
    Begin Object Class=KFGameExplosion Name=ExploTemplate0
        Damage=350
        DamageRadius=375
        DamageFalloffExponent=1.5
    End Object
}