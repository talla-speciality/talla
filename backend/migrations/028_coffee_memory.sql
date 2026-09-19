ALTER TABLE coffee_records DROP CONSTRAINT IF EXISTS coffee_records_entity_type;
ALTER TABLE coffee_records ADD CONSTRAINT coffee_records_entity_type CHECK (entity_type IN (
    'coffeeLot', 'purchasedCoffee', 'equipment', 'calibration', 'recipe',
    'recipeVersion', 'brewSession', 'sample', 'tasteFeedback', 'maintenance',
    'waterProfile', 'temperaturePreset', 'doseUsage', 'favorite', 'savedCart', 'activeCart'
));
