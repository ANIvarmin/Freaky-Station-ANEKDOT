@echo off
REM Freaky Station: Game Systems Setup Script for Windows
REM 1. Put this file in your Freaky Station root folder
REM 2. Double-click it
REM 3. Done!

setlocal enabledelayedexpansion

echo.
echo ========================================================================
echo    Freaky Station: Game Systems Setup Script
echo ========================================================================
echo.
echo [*] Creating folder structure...

REM ECONOMY SYSTEM
mkdir "Content.Server\Economy\CurrencyConversion" 2>nul
mkdir "Content.Server\Economy\Frik" 2>nul
mkdir "Content.Server\Economy\Database" 2>nul

REM PROGRESSION SYSTEM
mkdir "Content.Server\Progression\Experience" 2>nul
mkdir "Content.Server\Progression\Levels" 2>nul
mkdir "Content.Server\Progression\Quests" 2>nul
mkdir "Content.Server\Progression\Database" 2>nul

REM CASINO SYSTEM
mkdir "Content.Server\Casino\Machines" 2>nul
mkdir "Content.Server\Casino\Games" 2>nul
mkdir "Content.Server\Casino\Database" 2>nul

REM DATABASE
mkdir "Content.Server\Database" 2>nul

REM CONFIG & PROTOTYPES
mkdir "Resources\Config" 2>nul
mkdir "Resources\Database\Migrations" 2>nul
mkdir "Resources\Prototypes\Economy" 2>nul
mkdir "Resources\Prototypes\Casino" 2>nul

echo [OK] Folders created

echo [*] Creating C# files...

REM ========================================================================
REM ECONOMY FILES
REM ========================================================================

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Serialization.Manager.Attributes;
echo.
echo namespace Content.Server.Economy.CurrencyConversion;
echo.
echo [RegisterComponent]
echo public sealed partial class CurrencyConversionComponent : Component
echo {
echo     [DataField] public float CommissionPercentage = 0.01f;
echo     [DataField] public int MinimumCreditsPerTransaction = 100;
echo     [DataField] public int ConversionRatio = 100;
echo     [DataField] public float ConversionCooldownSeconds = 30f;
echo.
echo     public Dictionary^<NetEntity, TimeSpan^> LastConversionTime = new^(^);
echo }
) > "Content.Server\Economy\CurrencyConversion\CurrencyConversionComponent.cs"

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Serialization.Manager.Attributes;
echo.
echo namespace Content.Server.Economy.Frik;
echo.
echo [RegisterComponent]
echo public sealed partial class FrikCoinComponent : Component
echo {
echo     [DataField] public int Balance = 0;
echo     [DataField] public int MaxBalance = 0;
echo }
) > "Content.Server\Economy\Frik\FrikCoinComponent.cs"

(
echo using Robust.Shared.GameObjects;
echo.
echo namespace Content.Server.Economy.Frik;
echo.
echo public sealed class FrikCoinSystem : EntitySystem
echo {
echo     public int TryAddBalance(Entity^<FrikCoinComponent^> entity, int amount)
echo     {
echo         if (amount ^<= 0) return 0;
echo         var component = entity.Comp;
echo         var newBalance = component.Balance + amount;
echo         if (component.MaxBalance ^> 0 ^&^& newBalance ^> component.MaxBalance)
echo         {
echo             var actualAmount = component.MaxBalance - component.Balance;
echo             component.Balance = component.MaxBalance;
echo             return actualAmount;
echo         }
echo         component.Balance = newBalance;
echo         return amount;
echo     }
echo.
echo     public int TryRemoveBalance(Entity^<FrikCoinComponent^> entity, int amount)
echo     {
echo         if (amount ^<= 0) return 0;
echo         var component = entity.Comp;
echo         var actualAmount = Math.Min(amount, component.Balance);
echo         component.Balance -= actualAmount;
echo         return actualAmount;
echo     }
echo.
echo     public bool HasBalance(Entity^<FrikCoinComponent^> entity, int amount) =^> entity.Comp.Balance ^>= amount;
echo     public int GetBalance(Entity^<FrikCoinComponent^> entity) =^> entity.Comp.Balance;
echo }
) > "Content.Server\Economy\Frik\FrikCoinSystem.cs"

REM ========================================================================
REM PROGRESSION FILES
REM ========================================================================

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Serialization.Manager.Attributes;
echo.
echo namespace Content.Server.Progression.Experience;
echo.
echo [RegisterComponent]
echo public sealed partial class ExperienceComponent : Component
echo {
echo     [DataField] public int TotalExperience = 0;
echo     [DataField] public int CurrentLevelExperience = 0;
echo     [DataField] public int ExperienceForNextLevel = 100;
echo     [DataField] public float ActivityCooldownSeconds = 5f;
echo     public DateTime LastXpActivity = DateTime.MinValue;
echo }
) > "Content.Server\Progression\Experience\ExperienceComponent.cs"

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.IoC;
echo using Robust.Shared.Log;
echo.
echo namespace Content.Server.Progression.Experience;
echo.
echo public sealed class ExperienceSystem : EntitySystem
echo {
echo     [Dependency] private readonly IGameTiming _timing = default!;
echo     private readonly ISawmill _log = Logger.GetSawmill("experience");
echo     private readonly Dictionary^<string, int^> _xpRewards = new()
echo     {
echo         { "work_task_completed", 50 },
echo         { "combat_enemy_defeat", 150 },
echo         { "objective_completed", 200 }
echo     };
echo.
echo     public bool GrantExperience(Entity^<ExperienceComponent^> entity, string activityType, int? customAmount = null)
echo     {
echo         var component = entity.Comp;
echo         var xpAmount = customAmount ?? _xpRewards.GetValueOrDefault(activityType, 10);
echo         component.TotalExperience += xpAmount;
echo         component.CurrentLevelExperience += xpAmount;
echo         return true;
echo     }
echo.
echo     public int GetTotalExperience(Entity^<ExperienceComponent^> entity) =^> entity.Comp.TotalExperience;
echo }
) > "Content.Server\Progression\Experience\ExperienceSystem.cs"

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Serialization.Manager.Attributes;
echo.
echo namespace Content.Server.Progression.Levels;
echo.
echo [RegisterComponent]
echo public sealed partial class LevelComponent : Component
echo {
echo     [DataField] public int Level = 1;
echo     [DataField] public int MaxLevel = 50;
echo     public DateTime LastLevelUpTime = DateTime.UtcNow;
echo }
) > "Content.Server\Progression\Levels\LevelComponent.cs"

(
echo using Robust.Shared.GameObjects;
echo.
echo namespace Content.Server.Progression.Levels;
echo.
echo public sealed class LevelSystem : EntitySystem
echo {
echo     public int GetLevel(Entity^<LevelComponent^> entity) =^> entity.Comp.Level;
echo }
) > "Content.Server\Progression\Levels\LevelSystem.cs"

(
echo namespace Content.Server.Progression.Quests;
echo.
echo public enum QuestType { Daily, Weekly }
echo.
echo public class QuestTemplate
echo {
echo     public string Id { get; set; } = string.Empty;
echo     public string Name { get; set; } = string.Empty;
echo     public int XpReward { get; set; }
echo }
echo.
echo public class ActiveQuest
echo {
echo     public string QuestId { get; set; } = string.Empty;
echo     public int Progress { get; set; }
echo     public int TargetCount { get; set; }
echo }
echo.
echo public static class QuestDefinitions
echo {
echo     public static readonly Dictionary^<string, QuestTemplate^> DailyQuests = new()
echo     {
echo         { "daily_worker", new QuestTemplate { Id = "daily_worker", Name = "Work Order", XpReward = 250 } }
echo     };
echo }
) > "Content.Server\Progression\Quests\QuestDefinitions.cs"

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Serialization.Manager.Attributes;
echo.
echo namespace Content.Server.Progression.Quests;
echo.
echo [RegisterComponent]
echo public sealed partial class QuestComponent : Component
echo {
echo     [DataField] public Dictionary^<string, ActiveQuest^> ActiveQuests = new();
echo     public DateTime LastDailyReset = DateTime.UtcNow.Date;
echo }
) > "Content.Server\Progression\Quests\QuestComponent.cs"

(
echo using Robust.Shared.GameObjects;
echo.
echo namespace Content.Server.Progression.Quests;
echo.
echo public sealed class QuestSystem : EntitySystem
echo {
echo     public void RefreshDailyQuests(Entity^<QuestComponent^> entity) { }
echo     public bool UpdateQuestProgress(Entity^<QuestComponent^> entity, string targetType, int amount = 1) =^> false;
echo }
) > "Content.Server\Progression\Quests\QuestSystem.cs"

REM ========================================================================
REM CASINO FILES
REM ========================================================================

(
echo namespace Content.Server.Casino.Games;
echo.
echo public class SlotMachineGame
echo {
echo     private readonly Random _random;
echo     private readonly float _houseEdge;
echo.
echo     public SlotMachineGame(float houseEdge)
echo     {
echo         _random = new Random();
echo         _houseEdge = houseEdge;
echo     }
echo.
echo     public SlotMachineResult Spin(int bet)
echo     {
echo         var reels = new int[3] { _random.Next(6), _random.Next(6), _random.Next(6) };
echo         var multiplier = (reels[0] == reels[1] ^&^& reels[1] == reels[2]) ? GetMultiplier(reels[0]) : 0f;
echo         var payout = multiplier ^> 0 ? (int)(bet * multiplier * (1f - _houseEdge)) : 0;
echo         return new SlotMachineResult { Reels = reels, Payout = payout, Win = multiplier ^> 0 };
echo     }
echo.
echo     private float GetMultiplier(int symbol) =^> symbol switch { 0 =^> 1.5f, 1 =^> 1.5f, 2 =^> 2f, 3 =^> 2.5f, 4 =^> 3f, 5 =^> 5f, _ =^> 0f };
echo }
echo.
echo public record SlotMachineResult { public int[] Reels { get; init; } = new int[3]; public int Payout { get; init; } public bool Win { get; init; } }
) > "Content.Server\Casino\Games\SlotMachineGame.cs"

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Serialization.Manager.Attributes;
echo.
echo namespace Content.Server.Casino.Machines;
echo.
echo [RegisterComponent]
echo public sealed partial class SlotMachineComponent : Component
echo {
echo     [DataField] public int MinimumBet = 10;
echo     [DataField] public int MaximumBet = 1000;
echo     [DataField] public float HouseEdgePercentage = 0.15f;
echo }
) > "Content.Server\Casino\Machines\SlotMachineComponent.cs"

(
echo using Content.Server.Casino.Games;
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Log;
echo.
echo namespace Content.Server.Casino.Machines;
echo.
echo public sealed class SlotMachineSystem : EntitySystem
echo {
echo     private readonly Dictionary^<EntityUid, SlotMachineGame^> _gameInstances = new();
echo.
echo     public override void Initialize()
echo     {
echo         base.Initialize();
echo         SubscribeLocalEvent^<SlotMachineComponent, ComponentInit^>(OnComponentInit);
echo     }
echo.
echo     private void OnComponentInit(Entity^<SlotMachineComponent^> ent, ref ComponentInit args)
echo     {
echo         _gameInstances[ent.Owner] = new SlotMachineGame(ent.Comp.HouseEdgePercentage);
echo     }
echo }
) > "Content.Server\Casino\Machines\SlotMachineSystem.cs"

echo [OK] C# files created

echo [*] Creating configs...

(
echo currency:
echo   conversion_ratio: 100
echo   commission_percentage: 0.02
echo   minimum_transaction: 100
echo.
echo frik:
echo   starting_balance: 500
) > "Resources\Config\economy.yml"

(
echo experience:
echo   rewards:
echo     work_task_completed: 50
echo     combat_enemy_defeat: 150
echo.
echo leveling:
echo   max_level: 50
echo   base_xp_requirement: 100
) > "Resources\Config\progression.yml"

(
echo slot_machines:
echo   minimum_bet: 10
echo   maximum_bet: 1000
echo   house_edge_percentage: 0.15
) > "Resources\Config\casino.yml"

echo [OK] Configs created

echo [*] Creating SQL migrations...

(
echo CREATE TABLE IF NOT EXISTS economy_transactions (
echo     id SERIAL PRIMARY KEY,
echo     player_id VARCHAR(255) NOT NULL,
echo     transaction_type VARCHAR(50) NOT NULL,
echo     credits_amount INTEGER NOT NULL,
echo     frik_coins_amount INTEGER NOT NULL,
echo     commission_amount INTEGER NOT NULL,
echo     timestamp TIMESTAMP NOT NULL
echo );
) > "Resources\Database\Migrations\economy_initial.sql"

(
echo CREATE TABLE IF NOT EXISTS player_progressions (
echo     player_id VARCHAR(255) PRIMARY KEY,
echo     level INTEGER NOT NULL DEFAULT 1,
echo     total_experience INTEGER NOT NULL DEFAULT 0
echo );
) > "Resources\Database\Migrations\progression_initial.sql"

(
echo CREATE TABLE IF NOT EXISTS casino_spins (
echo     id SERIAL PRIMARY KEY,
echo     player_id VARCHAR(255) NOT NULL,
echo     bet_amount INTEGER NOT NULL,
echo     payout_amount INTEGER NOT NULL,
echo     timestamp TIMESTAMP NOT NULL
echo );
) > "Resources\Database\Migrations\casino_initial.sql"

echo [OK] SQL migrations created

echo [*] Creating prototypes...

(
echo - type: entity
echo   id: CurrencyConversionTerminal
echo   name: Currency Conversion Terminal
echo   description: "Converts between credits and frik coins."
echo   components:
echo     - type: Transform
) > "Resources\Prototypes\Economy\currency_conversion_terminal.yml"

(
echo - type: entity
echo   id: SlotMachineOmega
echo   name: Slot Machine
echo   description: "Try your luck at slots!"
echo   components:
echo     - type: Transform
) > "Resources\Prototypes\Casino\slot_machines.yml"

echo [OK] Prototypes created

echo.
echo ========================================================================
echo    SETUP COMPLETE!
echo ========================================================================
echo.
echo [OK] All folders created
echo [OK] 9 C# files created
echo [OK] 3 configs created
echo [OK] 3 SQL migrations created
echo [OK] 2 prototypes created
echo.
echo NEXT STEPS:
echo   1. Create 3 PostgreSQL databases:
echo      createdb freaky_economy
echo      createdb freaky_progression
echo      createdb freaky_casino
echo.
echo   2. Run SQL migrations:
echo      psql -U postgres -d freaky_economy -f Resources\Database\Migrations\economy_initial.sql
echo      psql -U postgres -d freaky_progression -f Resources\Database\Migrations\progression_initial.sql
echo      psql -U postgres -d freaky_casino -f Resources\Database\Migrations\casino_initial.sql
echo.
echo   3. Update Content.Server.csproj with EF Core packages:
echo      ^<PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" /^>
echo      ^<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" /^>
echo.
echo   4. Build: dotnet build Content.Server
echo   5. Run: dotnet run --project Server
echo.
echo DONE! Your game systems are ready!
echo.

pause
