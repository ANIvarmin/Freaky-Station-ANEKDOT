#!/bin/bash

################################################################################
# АВТОМАТИЧЕСКИЙ УСТАНОВЩИК ИГРОВЫХ СИСТЕМ FREAKY STATION
# Скопируйте этот скрипт в корневой каталог freaky-station и запустите: bash install-freaky-systems.sh
################################################################################

set -e # Выход при ошибке

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║ FREAKY STATION: УСТАНОВКА ТРЕХ ИГРОВЫХ СИСТЕМ ║" 
echo "║ Конвертация валюты | Прогресс | Казино ║" 
echo "╚════════════════════════════════════════════════════════════════════════╝"

# Цвета для вывода
КРАСНЫЙ = '\033[0;31m'
ЗЕЛЕНЫЙ = '\ 033[0; 32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Без цвета

# Проверить, находимся ли мы в нужном каталоге
if [ ! -d "Content.Server" ]; then
 echo -e "${RED}❌ Ошибка: каталог Content.Server не найден!${NC}"
 echo "Запустите этот скрипт из корня вашего репозитория freaky-station"
 выход 1 
fi

echo -e "$ {ЖЕЛТЫЙ} Создание структуры каталогов ... $ {NC}"

# Создание структуры каталогов 
содержимое mkdir -p.Сервер / Экономика / Конверсия валюты 
Содержимое mkdir -p.Сервер/Экономика /Фрик
mkdir -p Content.Server/Economy/Database
mkdir -p Content.Server/Progression/Experience
mkdir -p Content.Server/Progression/Levels
mkdir -p Content.Server/Progression/Quests
mkdir -p Content.Server/Progression/Database
mkdir -p Content.Server/Casino/Machines
mkdir -p Content.Server/Casino/Games
mkdir -p Content.Server/Casino/Database
mkdir -p Content.Сервер/База данных
mkdir -p Resources/Config
mkdir -p Resources/Database/Migrations
mkdir -p Resources/Prototypes/Economy
mkdir -p Resources/Prototypes/Casino

echo -e "${GREEN}✓ Директории созданы${NC}"

################################################################################
# СИСТЕМА КОНВЕРСИИ ВАЛЮТ
################################################################################

echo -e "${YELLOW}Создание системы конверсии валют...${NC}"

# CurrencyConversionComponent.cs
cat > Content.Server/Economy/CurrencyConversion/CurrencyConversionComponent.cs << 'EOF'
using Robust.Shared.GameObjects;
using Robust.Shared.Serialization.Manager.Attributes;

namespace Content.Server.Economy.CurrencyConversion;

[RegisterComponent]
public sealed partial class CurrencyConversionComponent : Component
{
 [DataField] public float CommissionPercentage = 0.01f;
 [DataField] public int MinimumCreditsPerTransaction = 100;
 [DataField] public int ConversionRatio = 100;
 [DataField] public float ConversionCooldownSeconds = 30f;
 
 public Dictionary<NetEntity, TimeSpan> LastConversionTime = new();
}
EOF

# CurrencyConversionSystem.cs
cat > Content.Server/Economy/CurrencyConversion/CurrencyConversionSystem.cs << 'EOF'
using Content.Server.Economy.Frik;
using Robust.Shared.GameObjects;
using Robust.Shared.IoC;
using Robust.Shared.Log;

namespace Content.Server.Economy.CurrencyConversion;

открытый закрытый класс CurrencyConversionSystem : EntitySystem
{
 [Зависимость] IGameTiming только для чтения _timing = по умолчанию!;
 частный ISawmill _log = регистратор, доступный только для чтения.GetSawmill("currency_conversion");

 общедоступная асинхронная задача<ConversionResult> Конвертировать кредиты в цифровую синхронизацию(
 NetEntity PlayerID, 
 int creditsAmount, 
 Сущность<CurrencyConversionComponent> конвертер) 
 {
 var component = converter.Comp;
 if (creditsAmount < component.MinimumCreditsPerTransaction)
 {
 return new ConversionResult { Success = false, ErrorMessage = $"Минимальная транзакция составляет {component.MinimumCreditsPerTransaction} кредитов" };
 }

 var now = _timing.CurTime;
 if (component.LastConversionTime.TryGetValue(playerId, out var lastTime))
 {
 var elapsed = now - lastTime;
 if (elapsed.TotalSeconds < component.ConversionCooldownSeconds)
 {
var remaining = component.ConversionCooldownSeconds - elapsed.TotalSeconds;
 return new ConversionResult { Success = false, ErrorMessage = $"Пожалуйста, подождите {remaining:F1} секунд, прежде чем конвертировать снова" };
 }
 }

 var baseFrikCoins = creditsAmount * component.ConversionRatio;
 var commissionAmount = (int)(baseFrikCoins * component.CommissionPercentage);
 var finalFrikCoins = baseFrikCoins - commissionAmount;

 component.LastConversionTime[playerId] = now;

 return new ConversionResult
 {
 Success = true,
 CreditsSpent = creditsAmount,
 FrikCoinsReceived = finalFrikCoins,
 CommissionCharged = commissionAmount
 };
 }
}

результат преобразования общедоступной записи
{
 общедоступный bool Success { get; init; }
 общедоступная строка? ErrorMessage { get; init; }
 public int CreditsSpent { получить; инициализировать; }
 public int FRIKCOINS received { получить; инициализировать; }
 public int Commission charged { получить; инициализировать; }
}
EOF

# FrikCoinКомпонент.cs 
cat > Содержимое.Server/Economy/Frik/FrikCoinComponent.cs << 'EOF'
using Robust.Shared.GameObjects;
using Robust.Shared.Serialization.Manager.Attributes;

namespace Content.Server.Economy.Frik;

[RegisterComponent]
public sealed partial class FrikCoinComponent : Component
{
 [Поле данных] public int Balance = 0;
 [Поле данных] public int MaxBalance = 0;
}
EOF

# FrikCoinSystem.cs 
cat > Содержимое.Сервер/Экономика/Фрик/FrikCoinSystem.cs << 'EOF'
использование Robust.Общий доступ.GameObjects;

содержимое пространства имен.Сервер.Эконом.Фрик;

общедоступный закрытый класс FrikCoinSystem : EntitySystem
{
 public int TryAddBalance(Entity<FrikCoinComponent> entity, int amount)
 { 
 if (amount <= 0) возвращает 0;
 var component = сущность.Comp;
 var newBalance = компонент.Баланс + сумма;
 если (компонент.MaxBalance > 0 && newBalance > компонент.MaxBalance)
 {
 var actualAmount = component.MaxBalance - component.Balance;
 component.Balance = component.MaxBalance;
 return actualAmount;
 }
 component.Balance = newBalance;
 return amount;
 }

 public int TryRemoveBalance(Entity<FrikCoinComponent> entity, int amount)
 {
 if (amount <= 0) return 0;
 var component = entity.Comp;
 var actualAmount = Math.Min(amount, component.Balance);
 component.Balance -= actualAmount;
 return actualAmount;
 }

 public bool HasBalance(Entity<FrikCoinComponent> entity, int amount) => entity.Comp.Balance >= amount;
 public int GetBalance(Entity<FrikCoinComponent> entity) => entity.Comp.Balance;
}
EOF

echo -e "${GREEN}✓ Система конвертации валют создана${NC}"

################################################################################
# СИСТЕМА ПРОГРЕССА
################################################################################

echo -e "${YELLOW}Создание системы прогресса...${NC}"

# ExperienceComponent.cs
cat > Content.Server/Progression/Experience/ExperienceComponent.cs << 'EOF'
using Robust.Shared.GameObjects;
using Robust.Shared.Serialization.Manager.Attributes;

namespace Content.Server.Progression.Experience;

[RegisterComponent]
public sealed partial class ExperienceComponent : Component
{
 [DataField] public int TotalExperience = 0;
 [DataField] public int CurrentLevelExperience = 0;
 [DataField] public int ExperienceForNextLevel = 100;
 [DataField] public float ActivityCooldownSeconds = 5f;
 public DateTime LastXpActivity = DateTime.MinValue;
}
EOF
# ExperienceSystem.cs
cat > Content.Server/Progression/Experience/ExperienceSystem.cs << 'EOF'
using Content.Server.Progression.Levels;
using Robust.Shared.GameObjects;
using Robust.Shared.IoC;
using Robust.Shared.Log;

namespace Content.Server.Progression.Experience;

public sealed class ExperienceSystem : EntitySystem
{
 [Dependency] private readonly IGameTiming _timing = default!;
 private readonly ISawmill _log = Logger.GetSawmill("experience");
 частный словарь только для чтения<string, int> _xpRewards = new()
 {
 { "work_task_completed", 50 }, 
 { "combat_enemy_defeat", 150 }, 
 { "objective_completed", 200 }, 
 { "skill_used", 25 }, 
 { "взаимодействие", 10 },
 { "exploration", 30 },
 { "role_performance", 100 }
 };

 public bool GrantExperience(Entity<ExperienceComponent> entity, string activityType, int? customAmount = null)
 {
 var component = entity.Comp;
 var now = _timing.CurTime;

 if ((now - TimeSpan.FromSeconds(component.Активныесекунды охлаждения)).TotalSeconds < (DateTime.UtcNow - component.LastXpActivity).TotalSeconds)
 return false;
 var xpAmount = customAmount ?? _xpRewards.GetValueOrDefault(activityType, 10);
 component.TotalExperience += xpAmount;
 component.CurrentLevelExperience += xpAmount;
 component.LastXpActivity = DateTime.UtcNow;

 return true;
 }

 public int получает общий опыт (Entity<компонент опыта> entity) => entity.Comp.Общий опыт;
 public int получает текущий уровень опыта(Entity<компонент опыта> entity) => entity.Comp.Текущий уровень опыта;
}
EOF

# LevelComponent.cs 
cat > Контент.Сервер/Прогрессия/Уровни/LevelComponent.cs << 'EOF'
использование Robust.Shared.GameObjects;
using Robust.Shared.Serialization.Manager.Attributes;

namespace Content.Server.Progression.Levels;

[RegisterComponent]
общедоступный запечатанный частичный класс LevelComponent : Component
{
 [DataField] public int Level = 1;
 [DataField] public int maxLevel = 50;
 общедоступный DateTime LastLevelUpTime = DateTime.UtcNow;
}
EOF

# LevelSystem.cs 
cat > Контент.Сервер/Прогрессия/Уровни/LevelSystem.cs << 'EOF'
использование контента.Сервер.Прогресс.Опыт;
using Robust.Shared.Игровые объекты;
using Robust.Shared.Лог;

namespace Content.Server.Прогресс.Уровни;

public sealed class LevelSystem : EntitySystem
{
 private readonly ISawmill _log = Logger.GetSawmill("levels");
 частный словарь только для чтения<int, int> _levelRequirements = GenerateLevelRequirements();

 общедоступный контрольный список bool (EntityUid entityUid, Entity<ExperienceComponent> expEntity, Entity<LevelComponent> levelEntity)
 {
 var (_, expComp) = затраты;
 var (_, levelComp) = levelEntity;

 if (expComp.CurrentLevelExperience >= expComp.ExperienceForNextLevel && levelComp.Level < levelComp.maxLevel)
 возвращает HandleLevelUp(entityUid, expEntity, levelEntity);

 возвращает false;
 }

 частный bool HandleLevelUp(EntityUid entityUid, Entity<ExperienceComponent> expEntity, Entity<LevelComponent> levelEntity)
 {
 var (_, expComp) = expEntity;
 var (_, levelComp) = levelEntity;

 var oldLevel = levelComp.Level;
 expComp.CurrentLevelExperience -= expComp.ExperienceForNextLevel;
 levelComp.Level = Math.Min(levelComp.Level + 1, levelComp.MaxLevel);
 levelComp.LastLevelUpTime = DateTime.UtcNow;

 if (_levelRequirements.Попробуйте получить значение(levelComp.Level + 1, out var nextLevelXp))
 expComp.ExperienceForNextLevel = nextLevelXp;

 _log.Info($"{entityUid} повышен уровень с {oldLevel} до {levelComp.Level}");
 возвращает true;
 }

 public int getLevel(Entity<LevelComponent> entity) => entity.Comp.Level;

 частный статический словарь<int, int> GenerateLevelRequirements()
 { 
 требования к var = новый словарь<int, int>();
 var baseXp = 100;
 множитель var = 1,15f;

 for (уровень int = 2; уровень <= 50; уровень ++)
 { 
 требуется переменная = (int)(baseXp * Math.Pow(множитель, уровень - 2));
 требования[уровень] = требуется;
 }

 требования к возврату;
 }
}
EOF

# QuestDefinitions.cs 
cat > Контент.Сервер/Прогрессия/Квесты/QuestDefinitions.cs << 'EOF'
namespace Content.Server.Progression.Quests;
public static class QuestDefinitions
{
 public static readonly Dictionary<string, QuestTemplate> DailyQuests = new()
 {
 { "daily_worker", new QuestTemplate { Id = "daily_worker", Name = "Рабочий заказ", Description = "Выполните 5 рабочих заданий", Type = QuestType.Daily, Target = "work_tasks", TargetCount = 5, XpReward = 250, FrikReward = 50 } },
 { "daily_explorer", новый шаблон квеста { Id = "daily_explorer", Name = "Испытание исследователя", Description = "Посетите 3 разных отдела", Type = QuestType.Daily, Target = "departments_visited", TargetCount = 3, XpReward = 200, FrikReward = 40 } },
 { "daily_combatant", new QuestTemplate { Id = "daily_combatant", Name = "Defender", Description = "Defeat 2 hostile entities", Type = QuestType.Ежедневно, Target = "enemies_defeated", targetCount = 2, XpReward = 300, FrikReward = 75 } }
 };

 общедоступный статический список<QuestTemplate> GetDailyQuestRotation(int seed)
 {
 var random = новый случайный список (начальный);
 var questList = ежедневные запросы.Значения.ToList();
 вращение переменной = новый список<QuestTemplate>();
 while (rotation.Count < 3 && questList.Count > 0)
 {
 var index = random.Next(questList.Count);
 rotation.Add(questList[index]);
 questList.RemoveAt(index);
 }
 return rotation;
 }
}

public class QuestTemplate
{
 public string Id { get; set; } = string.Empty;
 public string Name { get; set; } = string.Empty;
 public string Description { get; set; } = string.Empty;
 public QuestType Type { get; set; }
 public string Target { get; set; } = string.Empty;
 public int TargetCount { get; set; }
 public int XpReward { get; set; }
 public int FrikReward { get; set; }
}

public enum QuestType { Daily, Weekly, Objective, Special }

public class ActiveQuest
{
 public string QuestId { get; set; } = string.Empty;
 public string PlayerId { get; set; } = string.Empty;
 public int Progress { get; set; }
 public int TargetCount { get; set; }
 public bool Completed { get; set; }
 public DateTime StartTime { get; set; }
 public DateTime? CompletionTime { get; set; }
}
EOF

# QuestComponent.cs 
cat > Контент.Сервер /Прогрессия/Квесты/QuestComponent.cs << 'EOF'
с использованием Robust.Общий доступ.Игровые объекты;
использование Robust.Общий доступ.Сериализация.Менеджер.Атрибуты;

namespace Content.Server.Progression.Quests;
[RegisterComponent]
public sealed partial class QuestComponent : Component
{
 [DataField] public Dictionary<string, ActiveQuest> ActiveQuests = new();
 [DataField] public List<string> CompletedQuests = new();
 public DateTime LastDailyReset = DateTime.UtcNow.Date;
}
EOF

# QuestSystem.cs 
cat > Контент.Сервер/Прогрессия/Квесты/QuestSystem.cs << 'EOF'
использование контента.Сервер.Эконом.Frik; 
используя Robust.Общий доступ.Игровые объекты;
используя Robust.Общий доступ.Журнал;

содержимое пространства имен.Сервер.Прогресс.Задания;

public sealed class QuestSystem : EntitySystem
{
 [Dependency] private readonly IGameTiming _timing = default!;
 private readonly ISawmill _log = Logger.GetSawmill("quests");

 public void RefreshDailyQuests(Entity<QuestComponent> entity)
 {
 var component = entity.Comp;
 var today = DateTime.UtcNow.Date;

 if (component.LastDailyReset != today)
 {
 component.ActiveQuests.Clear();
 component.LastDailyReset = today;

 var seed = today.GetHashCode();
 var dailyQuests = QuestDefinitions.GetDailyQuestRotation(seed);

 foreach (var questTemplate in dailyQuests)
 {
 component.ActiveQuests[questTemplate.Id] = new ActiveQuest
 {
 QuestId = questTemplate.Id,
 PlayerId = entity.Owner.ToString(),
 Progress = 0,
 TargetCount = questTemplate.TargetCount,
 Completed = false,
 StartTime = DateTime.UtcNow
 };
 }

 _log.Debug($"Обновлены ежедневные задания для {entity.Owner}");
 }
 }

 public bool UpdateQuestProgress(Entity<QuestComponent> entity, string targetType, int amount = 1)
 {
 var component = entity.Comp;

 foreach (var (questId, quest) in component.ActiveQuests)
 {
 if (quest.Завершено) continue;
 if (QuestDefinitions.DailyQuests.TryGetValue(questId, out var template) && template.Target == targetType)
 {
 quest.Progress += amount;

 if (quest.Progress >= quest.TargetCount)
 {
 quest.Completed = true;
 quest.CompletionTime = DateTime.UtcNow;
 component.CompletedQuests.Add(questId);
 _log.Debug($"{entity.Owner} завершил квест {questId}");
 return true;
 }

 return false;
 }
 }

 return false;
 }

 public Dictionary<string, ActiveQuest> GetActiveQuests(Entity<QuestComponent> entity)
 {
 return new Dictionary<string, ActiveQuest>(entity.Comp.ActiveQuests);
 }
}
EOF

echo -e "${GREEN}✓ Система прогресса создана${NC}"

################################################################################
# СИСТЕМА КАЗИНО
################################################################################

echo -e "${YELLOW}Создание системы казино...${NC}"

# SlotMachineGame.cs
cat > Content.Server/Casino/Games/SlotMachineGame.cs << 'EOF'
namespace Content.Server.Casino.Games;

public class SlotMachineGame
{
 private readonly Random _random;
 private readonly float _houseEdge;

 private const int CHERRY = 0, LEMON = 1, ORANGE = 2, BELL = 3, BAR = 4, SEVEN = 5;
 public SlotMachineGame(float houseEdge)
 {
 _random = new Random();
 _houseEdge = houseEdge;
 }

 public SlotMachineResult Spin(int bet)
 {
 var reels = GenerateReels();
 var result = CalculatePayout(reels, bet);
 return new SlotMachineResult { Reels = reels, Bet = bet, Payout = result.Payout, Multiplier = result.Multiplier, Win = result.Win, Message = result.Message };
 }

 private int[] GenerateReels()
 {
 var reels = new int[3];
 for (int i = 0; i < 3; i++) reels[i] = GenerateWeightedReel();
 return reels;
 }

 private int GenerateWeightedReel()
 {
 var roll = _random.NextDouble();
 if (roll < 0.30) return CHERRY;
 if (roll < 0.55) return LEMON;
 if (roll < 0.75) return ORANGE;
 if (roll < 0.88) return BELL;
 if (roll < 0.97) return BAR;
 return SEVEN;
 }

 private PayoutResult CalculatePayout(int[] reels, int bet)
 {
 var reel1 = reels[0];
 var reel2 = reels[1];
 var reel3 = reels[2];

 if (reel1 == reel2 && reel2 == reel3)
 {
 var multiplier = GetSymbolMultiplier(reel1);
 var payout = (int)(bet * multiplier);
 var houseEarnings = (int)(payout * _houseEdge);
 выплата -= Домашнее обучение;

 верните новый результат выплаты { Выплата = payout, Множитель = multiplier, Выигрыш = true, Сообщение = $"Тройка в своем роде! Выиграйте {выплата} фриковые монеты!" };
 }

 вернуть новый результат выплаты { Выплата = 0, Множитель = 0, Выигрыш = false, Сообщение = "В следующий раз повезет больше!" }; 
 }

 private float GetSymbolMultiplier(int symbol) => symbol switch
 {
 CHERRY => 1.5f,
 LEMON => 1.5f,
 ORANGE => 2.0f,
 BELL => 2.5f,
 BAR => 3.0f,
 SEVEN => 5.0f,
 _ => 0f
 };
}

public record SlotMachineResult
{
 public int[] Reels { get; init; } = new int[3];
 public int Bet { get; init; }
 public int Payout { get; init; }
 public float Multiplier { get; init; }
 public bool Win { get; init; }
 public string Message { get; init; } = string.Empty;
}

общедоступный рекордный результат выплаты
{
 общедоступная выплата int { получить; инициализировать; }
 общедоступный множитель float { получить; инициализировать; }
 общедоступный выигрыш bool { получить; инициализировать; }
 общедоступное строковое сообщение { get; init; }
}
EOF

# SlotMachineComponent.cs 
cat > Содержимое.Сервер/Казино/Игровые автоматы/SlotMachineComponent.cs << 'EOF'
использование контента.Server.Casino.Games;
using Robust.Shared.GameObjects;
using Robust.Shared.Serialization.Manager.Attributes;

namespace Content.Server.Casino.Machines;

[RegisterComponent]
public sealed partial class SlotMachineComponent : Component
{
 [DataField] public int MinimumBet = 10;
 [DataField] public int MaximumBet = 1000;
 [DataField] public float HouseEdgePercentage = 0.15f;
 [DataField] public SlotMachineState CurrentState = SlotMachineState.Idle;
 [DataField] public int[] CurrentReels = { 0, 0, 0 };
 
 public NetEntity? CurrentPlayer = null;
 public int CurrentBet = 0;
 public SlotMachineResult? LastResult = null;
}

общедоступное перечисление SlotMachineState { Простаивает, вращается, показывает результат, ожидает ставки }
EOF

# SlotMachineSystem.cs 
cat > Содержимое.Сервер/Казино/Автоматы/SlotMachineSystem.cs << 'EOF'
использование контента.Сервер.Казино.Игры;
использование контента.Сервер.Эконом.Frik; 
использование Robust.Общий доступ.GameObjects;
using Robust.Shared.IoC;
using Robust.Shared.Log;

namespace Content.Server.Casino.Machines;

public sealed class SlotMachineSystem : EntitySystem
{
 [Dependency] private readonly IGameTiming _timing = default!;
 [Dependency] private readonly FrikCoinSystem _frikSystem = default!;

 private readonly ISawmill _log = Logger.GetSawmill("slot_machines");
 private readonly Dictionary<EntityUid, SlotMachineGame> _gameInstances = new();
 public override void Initialize()
 {
 base.Initialize();
 SubscribeLocalEvent<SlotMachineComponent, ComponentInit>(OnComponentInit);
 }

 закрытая пустота OnComponentInit(Entity<SlotMachineComponent> ent, ссылка на аргументы ComponentInit)
 {
 _log.Info($"Инициализирован игровой автомат: {ent.Владелец}");
 _gameInstances[ent.Владелец] = новая игровая машина (ent.Comp.Домашний центр);
 }

 общедоступная асинхронная задача<BetResult> PlaceBetAsync(объект<SlotMachineComponent> machine, NetEntity PlayerID, int betAmount)
 {
 var component = машина.Ставка;

 if (betAmount < компонент.Минимальная ставка)
 возвращает новый результат { Успех = false, ErrorMessage = $"Минимальная ставка равна {компонент.Минимальная ставка} фриковые монеты" };

 if (количество ставок > component.MaximumBet)
 возвращает новый результат { Успех = false, сообщение об ошибке = $"Максимальная ставка составляет {component.MaximumBet} фриковые монеты" };

 компонент.currentState = состояние игрового автомата.Вращающийся;
 компонент.CurrentPlayer = идентификатор игрока.;
 component.CurrentBet = betAmount;
 var game = _gameInstances[machine.Owner];
 var spinResult = game.Spin(betAmount);
 component.CurrentReels = spinResult.Reels;
 component.LastResult = spinResult;
 component.CurrentState = SlotMachineState.ShowingResult;

 return new BetResult { Success = true, Reels = spinResult.Reels, Payout = spinResult.Выплата, Сообщение = spinResult.Message };
 }
}

public record BetResult
{
 public bool Success { get; init; }
 public string? ErrorMessage { get; init; }
 public int[] Reels { get; init; } = new int[3];
 public int Payout { get; init; }
 public string Message { get; init; } = string.Empty;
}
EOF

echo -e "${ЗЕЛЕНЫЙ}✓ Создана система казино ${NC}"

################################################################################
# ФАЙЛЫ КОНФИГУРАЦИИ
################################################################################

echo -e "${ЖЕЛТЫЙ} Создание файлов конфигурации ... ${NC}"

# economy.yml 
cat > Ресурсы/Конфигурация/economy.yml << 'EOF'
валюта: 
 коэффициент конвертации: 100 
 процент комиссии: 0.02
 минимальная транзакция: 100 
 время конвертации: 30

фрик:
 starting_balance: 500
 max_balance: 0

database:
 log_transactions: true
 retention_days: 90
EOF

# progression.yml
cat > Resources/Config/progression.yml << 'EOF'
experience:
 rewards:
 work_task_completed: 50
 combat_enemy_defeat: 150
 objective_completed: 200
 skill_used: 25
 interaction: 10
 exploration: 30
 role_performance: 100
 grant_cooldown: 5

leveling:
 max_level: 50
 base_xp_requirement: 100
 level_multiplier: 1.15

quests:
 daily:
 quest_count: 3
 reset_hour: 0

database:
 persist_data: true
 backup_interval: 60
EOF

# casino.yml
cat > Resources/Config/casino.yml << 'EOF'
slot_machines:
 minimum_bet: 10
 maximum_bet: 1000
 house_edge_percentage: 0.15
 выплаты:
 вишня: 1.5
 лимон: 1.5
 апельсин: 2.0
 колокольчик: 2.5
 бар: 3.0
 семерка: 5.0

ограничения:
 дневной_лимит_убытка: 0
 лимит_сессии: 0

база данных:
 log_spins: true
 track_statistics: true
EOF

echo -e "${ЗЕЛЕНЫЙ} Созданы файлы конфигурации${NC}"

################################################################################
# МИГРАЦИИ SQL
################################################################################

echo -e "${YELLOW}Создание SQL-миграций...${NC}"
# economy_initial.sql
cat > Resources/Database/Migrations/economy_initial.sql << 'EOF'
CREATE TABLE IF NOT EXISTS economy_transactions (
 id SERIAL PRIMARY KEY,
 player_id VARCHAR(255) NOT NULL,
 transaction_type VARCHAR(50) NOT NULL,
 credits_amount INTEGER NOT NULL DEFAULT 0,
 frik_coins_amount INTEGER NOT NULL DEFAULT 0,
 commission_amount INTEGER NOT NULL DEFAULT 0,
 timestamp TIMESTAMP NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'pending',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_economy_player_id ON economy_transactions(player_id);
CREATE INDEX idx_economy_timestamp ON economy_transactions(timestamp);

CREATE TABLE IF NOT EXISTS player_frik_balances (
 player_id VARCHAR(255) PRIMARY KEY,
 balance INTEGER NOT NULL DEFAULT 0,
 last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
EOF

# progression_initial.sql 
cat > Ресурсы/База данных/Миграции/progression_initial.sql << 'EOF'
СОЗДАЙТЕ ТАБЛИЦУ, ЕСЛИ НЕ СУЩЕСТВУЕТ player_progressions ( 
 ПЕРВИЧНЫЙ КЛЮЧ ПЕРЕМЕННОЙ player_id(255), 
 целое число уровня НЕ РАВНО НУЛЮ ПО УМОЛЧАНИЮ 1,
 total_experience INTEGER NOT NULL DEFAULT 0,
 last_level_up_time TIMESTAMP NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quest_completions (
 id SERIAL PRIMARY KEY,
 player_id VARCHAR(255) NOT NULL,
 quest_id VARCHAR(255) NOT NULL,
 completion_time TIMESTAMP NOT NULL,