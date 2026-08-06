@echo off
REM #########################################################################
REM Freaky Station: Complete Setup Script for Windows
REM 
REM Использование:
REM 1. Положи этот файл в корень папки Freaky Station
REM 2. Дважды кликни на него
REM 3. Готово!
REM #########################################################################

setlocal enabledelayedexpansion

echo.
echo ========================================================================
echo    Freaky Station: Game Systems Setup Script (Windows)
echo ========================================================================
echo.
echo [*] Создаю структуру папок...

REM ========================================================================
REM ECONOMY SYSTEM FOLDERS
REM ========================================================================
if not exist "Content.Server\Economy\CurrencyConversion" mkdir "Content.Server\Economy\CurrencyConversion"
if not exist "Content.Server\Economy\Frik" mkdir "Content.Server\Economy\Frik"
if not exist "Content.Server\Economy\Database" mkdir "Content.Server\Economy\Database"

REM ========================================================================
REM PROGRESSION SYSTEM FOLDERS
REM ========================================================================
if not exist "Content.Server\Progression\Experience" mkdir "Content.Server\Progression\Experience"
if not exist "Content.Server\Progression\Levels" mkdir "Content.Server\Progression\Levels"
if not exist "Content.Server\Progression\Quests" mkdir "Content.Server\Progression\Quests"
if not exist "Content.Server\Progression\Database" mkdir "Content.Server\Progression\Database"

REM ========================================================================
REM CASINO SYSTEM FOLDERS
REM ========================================================================
if not exist "Content.Server\Casino\Machines" mkdir "Content.Server\Casino\Machines"
if not exist "Content.Server\Casino\Games" mkdir "Content.Server\Casino\Games"
if not exist "Content.Server\Casino\Database" mkdir "Content.Server\Casino\Database"

REM ========================================================================
REM DATABASE FOLDERS
REM ========================================================================
if not exist "Content.Server\Database" mkdir "Content.Server\Database"

REM ========================================================================
REM CONFIG & PROTOTYPE FOLDERS
REM ========================================================================
if not exist "Resources\Config" mkdir "Resources\Config"
if not exist "Resources\Database\Migrations" mkdir "Resources\Database\Migrations"
if not exist "Resources\Prototypes\Economy" mkdir "Resources\Prototypes\Economy"
if not exist "Resources\Prototypes\Casino" mkdir "Resources\Prototypes\Casino"

echo [OK] Папки созданы

echo [*] Создаю C# файлы...

REM ========================================================================
REM ECONOMY SYSTEM FILES
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
echo using Content.Server.Economy.Frik;
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.IoC;
echo using Robust.Shared.Log;
echo.
echo namespace Content.Server.Economy.CurrencyConversion;
echo.
echo public sealed class CurrencyConversionSystem : EntitySystem
echo {
echo     [Dependency] private readonly IGameTiming _timing = default!;
echo     private readonly ISawmill _log = Logger.GetSawmill("currency_conversion");
echo.
echo     public override void Initialize() =^> base.Initialize();
echo.
echo     public async Task^<ConversionResult^> ConvertCreditsToFrikAsync(
echo         NetEntity playerId, int creditsAmount, Entity^<CurrencyConversionComponent^> converter)
echo     {
echo         var component = converter.Comp;
echo         if (creditsAmount ^< component.MinimumCreditsPerTransaction)
echo             return new ConversionResult { Success = false, ErrorMessage = $"Minimum transaction is {component.MinimumCreditsPerTransaction} credits" };
echo.
echo         var now = _timing.CurTime;
echo         if (component.LastConversionTime.TryGetValue(playerId, out var lastTime))
echo         {
echo             var elapsed = now - lastTime;
echo             if (elapsed.TotalSeconds ^< component.ConversionCooldownSeconds)
echo                 return new ConversionResult { Success = false, ErrorMessage = $"Please wait {component.ConversionCooldownSeconds - elapsed.TotalSeconds:F1} seconds" };
echo         }
echo.
echo         var baseFrikCoins = creditsAmount * component.ConversionRatio;
echo         var commissionAmount = (int)(baseFrikCoins * component.CommissionPercentage);
echo         var finalFrikCoins = baseFrikCoins - commissionAmount;
echo         component.LastConversionTime[playerId] = now;
echo.
echo         return new ConversionResult { Success = true, CreditsSpent = creditsAmount, FrikCoinsReceived = finalFrikCoins, CommissionCharged = commissionAmount };
echo     }
echo }
echo.
echo public record ConversionResult
echo {
echo     public bool Success { get; init; }
echo     public string? ErrorMessage { get; init; }
echo     public int CreditsSpent { get; init; }
echo     public int FrikCoinsReceived { get; init; }
echo     public int CommissionCharged { get; init; }
echo }
) > "Content.Server\Economy\CurrencyConversion\CurrencyConversionSystem.cs"

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
REM PROGRESSION SYSTEM FILES
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
echo         { "objective_completed", 200 },
echo         { "skill_used", 25 },
echo         { "interaction", 10 },
echo         { "exploration", 30 },
echo         { "role_performance", 100 }
echo     };
echo.
echo     public bool GrantExperience(Entity^<ExperienceComponent^> entity, string activityType, int? customAmount = null)
echo     {
echo         var component = entity.Comp;
echo         var now = _timing.CurTime;
echo         if ((now - TimeSpan.FromSeconds(component.ActivityCooldownSeconds)).TotalSeconds ^< (DateTime.UtcNow - component.LastXpActivity).TotalSeconds)
echo             return false;
echo.
echo         var xpAmount = customAmount ?? _xpRewards.GetValueOrDefault(activityType, 10);
echo         component.TotalExperience += xpAmount;
echo         component.CurrentLevelExperience += xpAmount;
echo         component.LastXpActivity = DateTime.UtcNow;
echo         return true;
echo     }
echo.
echo     public int GetTotalExperience(Entity^<ExperienceComponent^> entity) =^> entity.Comp.TotalExperience;
echo     public int GetCurrentLevelExperience(Entity^<ExperienceComponent^> entity) =^> entity.Comp.CurrentLevelExperience;
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
echo using Robust.Shared.Log;
echo.
echo namespace Content.Server.Progression.Levels;
echo.
echo public sealed class LevelSystem : EntitySystem
echo {
echo     private readonly ISawmill _log = Logger.GetSawmill("levels");
echo     private readonly Dictionary^<int, int^> _levelRequirements = GenerateLevelRequirements();
echo.
echo     public int GetLevel(Entity^<LevelComponent^> entity) =^> entity.Comp.Level;
echo.
echo     private static Dictionary^<int, int^> GenerateLevelRequirements()
echo     {
echo         var requirements = new Dictionary^<int, int^>();
echo         var baseXp = 100;
echo         var multiplier = 1.15f;
echo         for (int level = 2; level ^<= 50; level++)
echo             requirements[level] = (int)(baseXp * Math.Pow(multiplier, level - 2));
echo         return requirements;
echo     }
echo }
) > "Content.Server\Progression\Levels\LevelSystem.cs"

(
echo namespace Content.Server.Progression.Quests;
echo.
echo public static class QuestDefinitions
echo {
echo     public static readonly Dictionary^<string, QuestTemplate^> DailyQuests = new()
echo     {
echo         { "daily_worker", new QuestTemplate { Id = "daily_worker", Name = "Work Order", Description = "Complete 5 work tasks", Type = QuestType.Daily, Target = "work_tasks", TargetCount = 5, XpReward = 250, FrikReward = 50 } },
echo         { "daily_explorer", new QuestTemplate { Id = "daily_explorer", Name = "Explorer's Challenge", Description = "Visit 3 departments", Type = QuestType.Daily, Target = "departments_visited", TargetCount = 3, XpReward = 200, FrikReward = 40 } },
echo         { "daily_combatant", new QuestTemplate { Id = "daily_combatant", Name = "Defender", Description = "Defeat 2 hostile entities", Type = QuestType.Daily, Target = "enemies_defeated", TargetCount = 2, XpReward = 300, FrikReward = 75 } }
echo     };
echo.
echo     public static List^<QuestTemplate^> GetDailyQuestRotation(int seed)
echo     {
echo         var random = new Random(seed);
echo         var questList = DailyQuests.Values.ToList();
echo         var rotation = new List^<QuestTemplate^>();
echo         while (rotation.Count ^< 3 ^&^& questList.Count ^> 0)
echo         {
echo             var index = random.Next(questList.Count);
echo             rotation.Add(questList[index]);
echo             questList.RemoveAt(index);
echo         }
echo         return rotation;
echo     }
echo }
echo.
echo public class QuestTemplate
echo {
echo     public string Id { get; set; } = string.Empty;
echo     public string Name { get; set; } = string.Empty;
echo     public string Description { get; set; } = string.Empty;
echo     public QuestType Type { get; set; }
echo     public string Target { get; set; } = string.Empty;
echo     public int TargetCount { get; set; }
echo     public int XpReward { get; set; }
echo     public int FrikReward { get; set; }
echo }
echo.
echo public enum QuestType { Daily, Weekly, Objective, Special }
echo.
echo public class ActiveQuest
echo {
echo     public string QuestId { get; set; } = string.Empty;
echo     public int Progress { get; set; }
echo     public int TargetCount { get; set; }
echo     public bool Completed { get; set; }
echo     public DateTime StartTime { get; set; }
echo     public DateTime? CompletionTime { get; set; }
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
echo     [DataField] public List^<string^> CompletedQuests = new();
echo     public DateTime LastDailyReset = DateTime.UtcNow.Date;
echo }
) > "Content.Server\Progression\Quests\QuestComponent.cs"

(
echo using Robust.Shared.GameObjects;
echo using Robust.Shared.Log;
echo.
echo namespace Content.Server.Progression.Quests;
echo.
echo public sealed class QuestSystem : EntitySystem
echo {
echo     private readonly ISawmill _log = Logger.GetSawmill("quests");
echo.
echo     public void RefreshDailyQuests(Entity^<QuestComponent^> entity)
echo     {
echo         var component = entity.Comp;
echo         var today = DateTime.UtcNow.Date;
echo         if (component.LastDailyReset != today)
echo         {
echo             component.ActiveQuests.Clear();
echo             component.LastDailyReset = today;
echo             var seed = today.GetHashCode();
echo             var dailyQuests = QuestDefinitions.GetDailyQuestRotation(seed);
echo             foreach (var questTemplate in dailyQuests)
echo             {
echo                 component.ActiveQuests[questTemplate.Id] = new ActiveQuest
echo                 {
echo                     QuestId = questTemplate.Id,
echo                     Progress = 0,
echo                     TargetCount = questTemplate.TargetCount,
echo                     Completed = false,
echo                     StartTime = DateTime.UtcNow
echo                 };
echo             }
echo             _log.Debug($"Daily quests refreshed for {entity.Owner}");
echo         }
echo     }
echo.
echo     public bool UpdateQuestProgress(Entity^<QuestComponent^> entity, string targetType, int amount = 1)
echo     {
echo         var component = entity.Comp;
echo         foreach (var (questId, quest) in component.ActiveQuests)
echo         {
echo             if (quest.Completed) continue;
echo             if (QuestDefinitions.DailyQuests.TryGetValue(questId, out var template) ^&^& template.Target == targetType)
echo             {
echo                 quest.Progress += amount;
echo                 if (quest.Progress ^>= quest.TargetCount)
echo                 {
echo                     quest.Completed = true;
echo                     quest.CompletionTime = DateTime.UtcNow;
echo                     component.CompletedQuests.Add(questId);
echo                     return true;
echo                 }
echo             }
echo         }
echo         return false;
echo     }
echo.
echo     public Dictionary^<string, ActiveQuest^> GetActiveQuests(Entity^<QuestComponent^> entity) =^> new(entity.Comp.ActiveQuests);
echo }
) > "Content.Server\Progression\Quests\QuestSystem.cs"

REM ========================================================================
REM CASINO SYSTEM FILES
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
echo         var reels = new int[3];
echo         for (int i = 0; i ^< 3; i++) reels[i] = GenerateWeightedReel();
echo         var result = CalculatePayout(reels, bet);
echo         return new SlotMachineResult { Reels = reels, Bet = bet, Payout = result.Payout, Multiplier = result.Multiplier, Win = result.Win, Message = result.Message };
echo     }
echo.
echo     private int GenerateWeightedReel()
echo     {
echo         var roll = _random.NextDouble();
echo         if (roll ^< 0.30) return 0;
echo         if (roll ^< 0.55) return 1;
echo         if (roll ^< 0.75) return 2;
echo         if (roll ^< 0.88) return 3;
echo         if (roll ^< 0.97) return 4;
echo         return 5;
echo     }
echo.
echo     private PayoutResult CalculatePayout(int[] reels, int bet)
echo     {
echo         if (reels[0] == reels[1] ^&^& reels[1] == reels[2])
echo         {
echo             var multiplier = GetSymbolMultiplier(reels[0]);
echo             var payout = (int)(bet * multiplier);
echo             var houseEarnings = (int)(payout * _houseEdge);
echo             payout -= houseEarnings;
echo             return new PayoutResult { Payout = payout, Multiplier = multiplier, Win = true, Message = $"Three of a kind! Win {payout} frik coins!" };
echo         }
echo         return new PayoutResult { Payout = 0, Multiplier = 0, Win = false, Message = "Better luck next time!" };
echo     }
echo.
echo     private float GetSymbolMultiplier(int symbol) =^> symbol switch
echo     {
echo         0 =^> 1.5f,
echo         1 =^> 1.5f,
echo         2 =^> 2.0f,
echo         3 =^> 2.5f,
echo         4 =^> 3.0f,
echo         5 =^> 5.0f,
echo         _ =^> 0f
echo     };
echo }
echo.
echo public record SlotMachineResult { public int[] Reels { get; init; } = new int[3]; public int Bet { get; init; } public int Payout { get; init; } public float Multiplier { get; init; } public bool Win { get; init; } public string Message { get; init; } = string.Empty; }
echo public record PayoutResult { public int Payout { get; init; } public float Multiplier { get; init; } public bool Win { get; init; } public string Message { get; init; } }
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
echo     [DataField] public int CurrentState = 0;
echo     [DataField] public int[] CurrentReels = { 0, 0, 0 };
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
echo     private readonly ISawmill _log = Logger.GetSawmill("slot_machines");
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
echo         _log.Info($"Slot machine initialized: {ent.Owner}");
echo         _gameInstances[ent.Owner] = new SlotMachineGame(ent.Comp.HouseEdgePercentage);
echo     }
echo.
echo     public BetResult PlaceBet(Entity^<SlotMachineComponent^> machine, int betAmount)
echo     {
echo         var component = machine.Comp;
echo         if (betAmount ^< component.MinimumBet)
echo             return new BetResult { Success = false, ErrorMessage = $"Minimum bet is {component.MinimumBet} frik coins" };
echo         if (betAmount ^> component.MaximumBet)
echo             return new BetResult { Success = false, ErrorMessage = $"Maximum bet is {component.MaximumBet} frik coins" };
echo.
echo         var game = _gameInstances[machine.Owner];
echo         var spinResult = game.Spin(betAmount);
echo         component.CurrentReels = spinResult.Reels;
echo         component.CurrentState = 2;
echo.
echo         return new BetResult { Success = true, Reels = spinResult.Reels, Payout = spinResult.Payout, Message = spinResult.Message };
echo     }
echo }
echo.
echo public record BetResult { public bool Success { get; init; } public string? ErrorMessage { get; init; } public int[] Reels { get; init; } = new int[3]; public int Payout { get; init; } public string Message { get; init; } = string.Empty; }
) > "Content.Server\Casino\Machines\SlotMachineSystem.cs"

echo [OK] C# файлы созданы

echo [*] Создаю конфиги...

(
echo currency:
echo   conversion_ratio: 100
echo   commission_percentage: 0.02
echo   minimum_transaction: 100
echo   conversion_cooldown: 30
echo.
echo frik:
echo   starting_balance: 500
echo   max_balance: 0
echo.
echo database:
echo   log_transactions: true
echo   retention_days: 90
) > "Resources\Config\economy.yml"

(
echo experience:
echo   rewards:
echo     work_task_completed: 50
echo     combat_enemy_defeat: 150
echo     objective_completed: 200
echo     skill_used: 25
echo     interaction: 10
echo     exploration: 30
echo     role_performance: 100
echo   grant_cooldown: 5
echo.
echo leveling:
echo   max_level: 50
echo   base_xp_requirement: 100
echo   level_multiplier: 1.15
echo.
echo quests:
echo   daily:
echo     quest_count: 3
echo     reset_hour: 0
echo.
echo database:
echo   persist_data: true
echo   backup_interval: 60
) > "Resources\Config\progression.yml"

(
echo slot_machines:
echo   minimum_bet: 10
echo   maximum_bet: 1000
echo   house_edge_percentage: 0.15
echo   payouts:
echo     cherry: 1.5
echo     lemon: 1.5
echo     orange: 2.0
echo     bell: 2.5
echo     bar: 3.0
echo     seven: 5.0
echo.
echo limits:
echo   daily_loss_limit: 0
echo   session_limit: 0
echo.
echo database:
echo   log_spins: true
echo   track_statistics: true
) > "Resources\Config\casino.yml"

echo [OK] Конфиги созданы

echo [*] Создаю SQL миграции...

(
echo CREATE TABLE IF NOT EXISTS economy_transactions (
echo     id SERIAL PRIMARY KEY,
echo     player_id VARCHAR(255) NOT NULL,
echo     transaction_type VARCHAR(50) NOT NULL,
echo     credits_amount INTEGER NOT NULL DEFAULT 0,
echo     frik_coins_amount INTEGER NOT NULL DEFAULT 0,
echo     commission_amount INTEGER NOT NULL DEFAULT 0,
echo     timestamp TIMESTAMP NOT NULL,
echo     status VARCHAR(20) NOT NULL DEFAULT 'pending',
echo     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
echo );
echo.
echo CREATE INDEX idx_economy_player_id ON economy_transactions(player_id);
echo CREATE INDEX idx_economy_timestamp ON economy_transactions(timestamp);
echo.
echo CREATE TABLE IF NOT EXISTS player_frik_balances (
echo     player_id VARCHAR(255) PRIMARY KEY,
echo     balance INTEGER NOT NULL DEFAULT 0,
echo     last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
echo );
) > "Resources\Database\Migrations\economy_initial.sql"

(
echo CREATE TABLE IF NOT EXISTS player_progressions (
echo     player_id VARCHAR(255) PRIMARY KEY,
echo     level INTEGER NOT NULL DEFAULT 1,
echo     total_experience INTEGER NOT NULL DEFAULT 0,
echo     last_level_up_time TIMESTAMP NOT NULL,
echo     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
echo );
echo.
echo CREATE TABLE IF NOT EXISTS quest_completions (
echo     id SERIAL PRIMARY KEY,
echo     player_id VARCHAR(255) NOT NULL,
echo     quest_id VARCHAR(255) NOT NULL,
echo     completion_time TIMESTAMP NOT NULL,
echo     xp_reward INTEGER NOT NULL DEFAULT 0,
echo     frik_reward INTEGER NOT NULL DEFAULT 0,
echo     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
echo );
echo.
echo CREATE INDEX idx_quest_player_id ON quest_completions(player_id);
echo CREATE INDEX idx_quest_id ON quest_completions(quest_id);
) > "Resources\Database\Migrations\progression_initial.sql"

(
echo CREATE TABLE IF NOT EXISTS casino_spins (
echo     id SERIAL PRIMARY KEY,
echo     player_id VARCHAR(255) NOT NULL,
echo     machine_id VARCHAR(255) NOT NULL,
echo     bet_amount INTEGER NOT NULL,
echo     payout_amount INTEGER NOT NULL DEFAULT 0,
echo     win_type VARCHAR(20) NOT NULL,
echo     timestamp TIMESTAMP NOT NULL,
echo     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
echo );
echo.
echo CREATE INDEX idx_casino_player_id ON casino_spins(player_id);
echo CREATE INDEX idx_casino_timestamp ON casino_spins(timestamp);
) > "Resources\Database\Migrations\casino_initial.sql"

echo [OK] SQL миграции созданы

echo [*] Создаю прототипы...

(
echo - type: entity
echo   id: CurrencyConversionTerminal
echo   name: Currency Conversion Terminal
echo   description: "Converts between credits and frik coins."
echo   components:
echo     - type: Transform
echo     - type: Sprite
echo       sprite: Objects/Specific/Economy/conversion_terminal.rsi
echo       state: base
echo     - type: CurrencyConversion
echo       commissionPercentage: 0.02
echo       minimumCreditsPerTransaction: 100
echo       conversionRatio: 100
echo       conversionCooldownSeconds: 30.0
) > "Resources\Prototypes\Economy\currency_conversion_terminal.yml"

(
echo - type: entity
echo   id: SlotMachineOmega
echo   name: Slot Machine
echo   description: "Try your luck at slots!"
echo   components:
echo     - type: Transform
echo     - type: Sprite
echo       sprite: Objects/Specific/Casino/slot_machine.rsi
echo       state: base
echo     - type: SlotMachine
echo       minimumBet: 10
echo       maximumBet: 1000
echo       houseEdgePercentage: 0.15
) > "Resources\Prototypes\Casino\slot_machines.yml"

echo [OK] Прототипы созданы

echo [*] Создаю README...

(
echo =============================================================================
echo FREAKY STATION GAME SYSTEMS - SETUP COMPLETE!
echo =============================================================================
echo.
echo Успешно созданы:
echo   [OK] 12 C# файлов (код систем)
echo   [OK] 3 конфига (YAML)
echo   [OK] 3 SQL миграции (PostgreSQL)
echo   [OK] 2 прототипа (сущности)
echo.
echo Папки созданы в:
echo   - Content.Server\Economy\
echo   - Content.Server\Progression\
echo   - Content.Server\Casino\
echo   - Resources\Config\
echo   - Resources\Database\Migrations\
echo   - Resources\Prototypes\
echo.
echo СЛЕДУЮЩИЕ ШАГИ:
echo.
echo 1. Создать 3 базы данных PostgreSQL:
echo    Открой pgAdmin или используй psql:
echo    CREATE DATABASE freaky_economy;
echo    CREATE DATABASE freaky_progression;
echo    CREATE DATABASE freaky_casino;
echo.
echo 2. Запустить SQL миграции:
echo    psql -U postgres -d freaky_economy -f Resources\Database\Migrations\economy_initial.sql
echo    psql -U postgres -d freaky_progression -f Resources\Database\Migrations\progression_initial.sql
echo    psql -U postgres -d freaky_casino -f Resources\Database\Migrations\casino_initial.sql
echo.
echo 3. Обновить Content.Server.csproj:
echo    Добавить в ^<ItemGroup^>:
echo    ^<PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" /^>
echo    ^<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" /^>
echo.
echo 4. Собрать проект:
echo    dotnet build Content.Server
echo.
echo 5. Запустить сервер:
echo    dotnet run --project Server
echo.
echo ГОТОВО! Три игровые системы теперь часть твоего сервера!
echo =============================================================================
) > "SETUP_README.txt"

echo [OK] README создан

echo.
echo ========================================================================
echo    SETUP ЗАВЕРШЕН!
echo ========================================================================
echo.
echo [OK] Структура папок создана
echo [OK] 12 C# файлов создано
echo [OK] 3 YAML конфига создано
echo [OK] 3 SQL миграции создано
echo [OK] 2 прототипа создано
echo.
echo Следующие шаги:
echo   1. Создать 3 БД PostgreSQL (economy, progression, casino)
echo   2. Запустить SQL миграции
echo   3. Обновить Content.Server.csproj (добавить EF Core пакеты)
echo   4. Собрать: dotnet build Content.Server
echo   5. Запустить: dotnet run
echo.
echo Подробности смотри в SETUP_README.txt
echo.

pause
