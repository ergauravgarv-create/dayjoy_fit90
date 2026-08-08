// Dayjoy "Health Care Product Recommendation Chart" — the disease → product
// database used to auto-suggest supplements. The system proposes the first
// 3–4 products for a diagnosed issue; the consulting doctor then edits/approves.
//
// Source: Dayjoy Health Product Recommendation Chart (English).

/// Full Dayjoy product catalogue with a sensible default dosage (the doctor
/// can change dosage/timing during review).
const Map<String, String> kProductDosage = {
  'Multivitamin Tablets': '1 tablet daily after breakfast',
  'HB+ Syrup': '10 ml twice daily',
  'Calcium Tablet': '1 tablet daily',
  'Golden Elixir': '30 ml with water daily',
  'Sea Buckthorn Juice': '30 ml with water daily',
  'Super Rich Berry Juice': '30 ml with water daily',
  'Super Food Capsule': '1 capsule daily',
  'BR Rich Oil': 'Apply / massage as directed',
  'Vital Protein': '1 scoop (~10 g) daily',
  'L-Arginine++ (Nitric Oxide Precursor)': 'As directed, pre-workout',
  'Dibeat Tablets': '1 tablet twice daily before meals',
  'Aloe Vera Guava Juice': '30 ml with water, empty stomach',
  'Nonima Juice': '30 ml with water daily',
  'Livease Syrup': '10 ml twice daily',
  'Adilipo Tablet': '1 tablet twice daily',
  'Omega 3-6-9 Softgel Capsules': '1 softgel daily',
  'Gas-O-Free Syrup': '10 ml twice daily',
  'Orthofix Tablet': '1 tablet twice daily',
  'Orthofix Oil': 'Massage on the affected area',
  'Adiliv Tablets': '1 tablet twice daily',
  'Arogya Churn': '1 tsp with warm water at night',
  'Go Piles Tablets': '1 tablet twice daily',
  'Gopiles Syrup': '10 ml twice daily',
  'Hi-Energy Tablets': '1 tablet daily',
  'Premium Tulsi Max': 'As directed / for steam inhalation',
  'Adilaforte Tablet': '1 tablet daily',
  'Adicardial Tablet': '1 tablet twice daily',
  'Adicardial Syrup': '10 ml twice daily',
  'Ample Meal': '1 serving as a meal replacement',
  'Aloe Vera Gel': 'Apply as directed',
  'Kidney Kawach': '1 tablet twice daily',
  'Eye Elixir Drops': 'As directed',
  'Eye Health++ Tablets': '1 tablet daily',
  'Asthprash': '1 tsp twice daily',
  'N-Astheal Tablet': '1 tablet twice daily',
  // --- Amara Beauty / Wild Muse skincare (cleanse–tone–moisturize) ---
  'AcneX Anti-Acne Foaming Cleanser':
      'Massage onto wet face, rinse; morning & evening',
  'Deep Cleansing Face Wash': 'Massage on wet face, rinse; daily',
  'Anti-Pollution Aloe Vera Face Wash': 'Massage on wet face, rinse; daily',
  'Haldi Chandan Face Wash': 'Massage on wet face, rinse; daily',
  'Sea Buckthorn Cleanser': 'Massage on damp skin, rinse; daily',
  'Face Serum (Niacinamide + Hyaluronic Acid)':
      '2–3 drops on damp face, twice daily',
  'Hydra Max Gel Moisturizer': 'Apply to face & neck, morning & night',
  'Daily Care Cream': 'Apply on face as needed',
  'AgeX Night Cream': 'Apply at night on cleansed face & neck',
  'Sunscreen SPF 50+': 'Apply each morning; reapply every 2–3 hrs',
  'Aloe Vera Gel': 'Apply a thin layer as needed',
  'Sea Buckthorn Facial Fluid': 'A few drops massaged into skin',
  'Neem & Aloe Vera Soap': 'Use to cleanse face & body, daily',
  'Luxury Saffron Soap': 'Use to cleanse face & body, daily',
  'Hydra Aloe Vera Body Lotion': 'Apply to body, especially after bathing',
};

class ChartRule {
  const ChartRule({
    required this.products,
    required this.eat,
    required this.avoid,
    required this.benefits,
  });
  final List<String> products; // first-choice products (3–4)
  final List<String> eat;
  final List<String> avoid;
  final List<String> benefits;
}

/// Conditions in display order.
const List<String> kSupplementConditions = [
  'General Health & Well-being',
  'Diabetes',
  'Heart Disease',
  'Bone & Joint Problems',
  'Liver Disease',
  'Digestion (Indigestion / Acidity)',
  'Piles / Fissure',
  'Low Immunity',
  'Respiratory Health',
  'Male Health',
  'Female Health (Hormonal Imbalance)',
  'Female Health (Weakness / Anaemia)',
  'Weight Management',
  'Skin Problems',
  'Brain Health / Cognitive',
  'Varicose Veins',
  'Sciatica',
  'Kidney (Stone / Uric Acid / UTI)',
  'Thyroid (Hypothyroidism)',
  'Eye Health',
  'Elderly Health',
  'Sinusitis',
  'Healthy Sleep',
  'Hair / Nail Health',
];

const Map<String, ChartRule> kChartRules = {
  'General Health & Well-being': ChartRule(
    products: [
      'Multivitamin Tablets',
      'HB+ Syrup',
      'Calcium Tablet',
      'Golden Elixir'
    ],
    eat: ['Fruits', 'Lean fish & chicken', 'Leafy greens', 'Eggs & nuts', 'Whole grains'],
    avoid: [],
    benefits: ['Boosts energy & immunity', 'Supports healthy hair, skin & nails'],
  ),
  'Diabetes': ChartRule(
    products: [
      'Dibeat Tablets',
      'Golden Elixir',
      'Aloe Vera Guava Juice',
      'Livease Syrup'
    ],
    eat: ['High-fibre fruits & vegetables', 'Whole grains', 'Multigrain roti / brown rice', 'Low-fat dairy'],
    avoid: ['Sugar & sweets', 'Refined carbs (maida, white rice)', 'Red meat (limit)'],
    benefits: ['Regulates sugar metabolism', 'Supports insulin secretion', 'Useful in pre / newly-diagnosed diabetes'],
  ),
  'Heart Disease': ChartRule(
    products: ['Adilipo Tablet', 'Golden Elixir', 'Gas-O-Free Syrup'],
    eat: ['High-fibre fruits & vegetables', 'Whole grains', 'Low-fat dairy'],
    avoid: ['Fried food', 'Red meat (limit)', 'Excess salt'],
    benefits: ['Improves heart function & circulation', 'Controls BP & cholesterol', 'Reduces plaque build-up'],
  ),
  'Bone & Joint Problems': ChartRule(
    products: [
      'Orthofix Tablet',
      'Orthofix Oil',
      'Calcium Tablet',
      'Golden Elixir'
    ],
    eat: ['Milk, cheese & dairy', 'Green leafy vegetables', 'Soya & tofu', 'Nuts & fortified flour'],
    avoid: [],
    benefits: ['Relieves joint pain & arthritis', 'Strengthens bones', 'Improves mobility & flexibility'],
  ),
  'Liver Disease': ChartRule(
    products: ['Adiliv Tablets', 'Livease Syrup', 'Golden Elixir'],
    eat: ['MUFA/PUFA & omega-3 fats', 'Plant proteins', 'Dietary fibre', 'Multigrain roti / brown rice'],
    avoid: ['Alcohol', 'Saturated & trans fats', 'Simple sugars', 'Red meat'],
    benefits: ['Detoxifies the body', 'Improves liver function', 'Useful in fatty liver'],
  ),
  'Digestion (Indigestion / Acidity)': ChartRule(
    products: [
      'Livease Syrup',
      'Arogya Churn',
      'Aloe Vera Guava Juice',
      'Super Rich Berry Juice'
    ],
    eat: ['Fibre (bran, wholemeal roti, cereals)', 'Fruit & leafy vegetables', 'Beans & lean protein', 'Low-fat milk'],
    avoid: ['Caffeine', 'Alcohol', 'Fizzy drinks'],
    benefits: ['Promotes digestion', 'Relieves acidity, gas & constipation', 'Regulates bile flow'],
  ),
  'Piles / Fissure': ChartRule(
    products: [
      'Go Piles Tablets',
      'Gopiles Syrup',
      'Adiliv Tablets',
      'Livease Syrup'
    ],
    eat: ['High-fibre food', 'Whole grains & legumes', 'Vegetables & fruits', 'Multigrain roti / brown rice'],
    avoid: ['Alcohol & chocolates', 'Packaged & processed snacks', 'Salty & fried foods', 'High-caffeine drinks'],
    benefits: ['Anti-inflammatory, heals affected area', 'Manages constipation', 'Antiseptic & antiviral'],
  ),
  'Low Immunity': ChartRule(
    products: ['Hi-Energy Tablets', 'Golden Elixir', 'Multivitamin Tablets'],
    eat: ['Citrus fruits', 'Ginger, garlic & turmeric', 'Leafy greens', 'Dry fruits, nuts & berries'],
    avoid: [],
    benefits: ['Boosts immunity', 'Fights infections', 'Detoxifies the body'],
  ),
  'Respiratory Health': ChartRule(
    products: ['Adiliv Tablets', 'Livease Syrup', 'Golden Elixir'],
    eat: ['Antioxidant & vitamin C/E/D rich fruits & veg', 'Omega-3 & fish', 'Whole grains'],
    avoid: [],
    benefits: ['Immunity against respiratory infections', 'Relieves chest congestion', 'Supports lung function'],
  ),
  'Male Health': ChartRule(
    products: [
      'Adilaforte Tablet',
      'Super Food Capsule',
      'Golden Elixir',
      'Omega 3-6-9 Softgel Capsules'
    ],
    eat: ['Walnut, salmon & tuna', 'Oats & quinoa', 'Garlic & nuts', 'Chia & pumpkin seeds'],
    avoid: [],
    benefits: ['Improves circulation to vital organs', 'Maintains energy & stamina', 'Helps erectile dysfunction'],
  ),
  'Female Health (Hormonal Imbalance)': ChartRule(
    products: [
      'Adicardial Tablet',
      'Adicardial Syrup',
      'Golden Elixir',
      'Super Food Capsule'
    ],
    eat: ['Lean protein & vegetables', 'Chia & flax seeds', 'Nuts & olive oil', 'Whole grains (quinoa, brown rice)'],
    avoid: ['Caffeine & alcohol', 'Fried & processed foods', 'Full-fat dairy', 'White bread / high-GI carbs'],
    benefits: ['Useful in PCOD / PCOS', 'Balances hormones', 'Regulates periods', 'Reduces stress'],
  ),
  'Female Health (Weakness / Anaemia)': ChartRule(
    products: [
      'Multivitamin Tablets',
      'HB+ Syrup',
      'Adicardial Syrup',
      'Golden Elixir'
    ],
    eat: ['Green leafy vegetables', 'Whole grains & nuts', 'Eggs & dairy', 'Pulses, legumes, meat & fish'],
    avoid: [],
    benefits: ['Useful in iron deficiency & anaemia', 'Fights fatigue', 'Maintains haemoglobin'],
  ),
  'Weight Management': ChartRule(
    products: [
      'Ample Meal',
      'Vital Protein',
      'L-Arginine++ (Nitric Oxide Precursor)',
      'Sea Buckthorn Juice'
    ],
    eat: ['Low-GI foods', 'Fruits & vegetables', 'Whole grains & protein foods', 'Nuts, canola & olive oil'],
    avoid: ['Sugar & fried foods', 'Processed meat', 'Full-fat dairy & artificial sweeteners', 'White bread'],
    benefits: ['Reduces fat deposition & cholesterol', 'Boosts metabolism', 'Helps prevent weight regain'],
  ),
  'Skin Problems': ChartRule(
    products: [
      'Golden Elixir',
      'Aloe Vera Guava Juice',
      'Aloe Vera Gel',
      'Premium Tulsi Max'
    ],
    eat: ['Essential fatty acids', 'Vitamins A, D, E & zinc', 'High water intake (11–12 glasses/day)'],
    avoid: ['Coffee & fizzy drinks', 'Fried, smoked & processed meats', 'Excess carbs & sweets'],
    benefits: ['Antioxidant & anti-inflammatory', 'Glowing, healthy skin', 'Treats acne, aids wound healing'],
  ),
  'Brain Health / Cognitive': ChartRule(
    products: [
      'Golden Elixir',
      'Sea Buckthorn Juice',
      'Adilipo Tablet',
      'Super Food Capsule'
    ],
    eat: ['Omega-3 (fish, seafood)', 'Kale, beans & legumes', 'Olive oil, nuts & whole grains', 'Dairy & poultry'],
    avoid: [],
    benefits: ['Enhances memory & concentration', 'Supports brain function', 'Useful in depression & age-related memory loss'],
  ),
  'Varicose Veins': ChartRule(
    products: [
      'Golden Elixir',
      'Adilipo Tablet',
      'Super Food Capsule',
      'Omega 3-6-9 Softgel Capsules'
    ],
    eat: ['Fibre-rich apples, flaxseed & chia', 'Carrots & berries', 'Green leafy vegetables & whole grains'],
    avoid: ['Prolonged standing'],
    benefits: ['Aids circulation', 'Maintains BP', 'Reduces pain, itching & swelling'],
  ),
  'Sciatica': ChartRule(
    products: [
      'Golden Elixir',
      'Super Rich Berry Juice',
      'Adilipo Tablet',
      'Orthofix Tablet'
    ],
    eat: ['Fibre-rich apples, flaxseed & chia', 'Carrots & berries', 'Green leafy vegetables & whole grains'],
    avoid: [],
    benefits: ['Aids circulation', 'Reduces ache, pain & swelling', 'Improves nerve comfort'],
  ),
  'Kidney (Stone / Uric Acid / UTI)': ChartRule(
    products: [
      'Kidney Kawach',
      'Golden Elixir',
      'Sea Buckthorn Juice',
      'Nonima Juice'
    ],
    eat: ['Plenty of water', 'Moderate protein'],
    avoid: ['High-oxalate foods', 'Extra calcium supplements', 'High salt', 'High-dose vitamin C'],
    benefits: ['Protects kidney', 'Prevents stone recurrence', 'Helps chronic UTI'],
  ),
  'Thyroid (Hypothyroidism)': ChartRule(
    products: [
      'Adicardial Tablet',
      'Adicardial Syrup',
      'Golden Elixir',
      'Sea Buckthorn Juice'
    ],
    eat: ['Low-iodine diet', 'Fruits & vegetables', 'Gluten-free whole grains', 'Nuts & seeds'],
    avoid: ['Fluoride in drinking water'],
    benefits: ['Reduces inflammation', 'Increases energy', 'Supports metabolism & mood'],
  ),
  'Eye Health': ChartRule(
    products: [
      'Eye Elixir Drops',
      'Eye Health++ Tablets',
      'Golden Elixir',
      'Sea Buckthorn Juice'
    ],
    eat: ['Fish & seafood', 'Nuts, legumes & seeds', 'Citrus & leafy greens', 'Carrots, sweet potatoes & eggs'],
    avoid: [],
    benefits: ['Supports clear vision', 'Reduces eye fatigue & dryness', 'Protects from macular degeneration'],
  ),
  'Elderly Health': ChartRule(
    products: [
      'Multivitamin Tablets',
      'Hi-Energy Tablets',
      'Calcium Tablet',
      'Golden Elixir'
    ],
    eat: ['Fruits, vegetables & whole grains', 'Low-fat dairy & soya', 'Seafood, lean meat & eggs', 'Beans, nuts & seeds'],
    avoid: ['Empty calories', 'High-cholesterol & fatty foods'],
    benefits: ['Increases stamina & muscle power', 'Useful in senile dementia', 'Fulfils nutritional demands'],
  ),
  'Sinusitis': ChartRule(
    products: ['Asthprash', 'Premium Tulsi Max', 'Golden Elixir'],
    eat: ['Fish & seafood', 'Dark leafy greens', 'Honey, garlic & hot peppers', 'Pineapple & antioxidant foods'],
    avoid: [],
    benefits: ['Relieves sinus congestion & headache', 'Strengthens respiratory system', 'Protects from cold & cough'],
  ),
  'Healthy Sleep': ChartRule(
    products: ['Golden Elixir', 'Hi-Energy Tablets', 'Multivitamin Tablets'],
    eat: ['Plant-based meals & whole grains', 'Fresh fruits & vegetables', 'Nuts & legumes', 'Fish & olive oil'],
    avoid: ['Red meat & butter', 'Caffeine & alcohol'],
    benefits: ['Calming effect', 'Restores natural sleep rhythm', 'Reduces anxiety & stress'],
  ),
  'Hair / Nail Health': ChartRule(
    products: [
      'Multivitamin Tablets',
      'HB+ Syrup',
      'Calcium Tablet',
      'BR Rich Oil'
    ],
    eat: ['Fruits & lean meats (fish, chicken)', 'Salmon, leafy greens & beans', 'Eggs, nuts & whole grains', 'Berries, spinach & avocados'],
    avoid: [],
    benefits: ['Promotes healthy hair growth', 'Reduces hair loss', 'Strengthens nails'],
  ),
};

/// Product knowledge from the Dayjoy Product Brochure — shown to the doctor so
/// they can recommend/edit fast.
class ProductInfo {
  const ProductInfo({
    required this.tagline,
    required this.benefits,
    required this.dosage,
    this.ingredients = '',
  });
  final String tagline;
  final List<String> benefits;
  final String dosage;
  final String ingredients;
}

const Map<String, ProductInfo> kProductInfo = {
  'Dibeat Tablets': ProductInfo(
    tagline: 'Natural support for balanced blood sugar.',
    benefits: [
      'Helps regulate blood sugar naturally',
      'Supports insulin function & glucose metabolism',
      'Reduces frequent urination & fatigue',
      'Antioxidant-rich for daily wellness'
    ],
    dosage: 'Take 2 tablets twice daily, or as directed by physician',
    ingredients: 'Jamun, Karela, Gudmaar, Vijayasara, Methi',
  ),
  'Adilipo Tablet': ProductInfo(
    tagline: 'For a heart that beats stronger, naturally.',
    benefits: [
      'Supports cardiovascular wellness',
      'Helps manage cholesterol & lipids',
      'Promotes blood flow & circulation',
      'Rich in antioxidants & Omega-3'
    ],
    dosage: '1–2 tablets twice daily on an empty stomach in the morning',
    ingredients: 'Arjuna, Guggulu, Lahasun, Pushkarmula, Atasi',
  ),
  'Adiliv Tablets': ProductInfo(
    tagline: 'For complete liver care, naturally.',
    benefits: [
      'Promotes healthy liver function',
      'Supports detox & toxin removal',
      'Improves digestion & appetite',
      'Aids regeneration of liver cells'
    ],
    dosage: '1–2 tablets twice daily on an empty stomach in the morning',
    ingredients: 'Himsra, Kasani, Arjuna, Punarnava, Bhringaraja, Guduchi',
  ),
  'Livease Syrup': ProductInfo(
    tagline: 'For complete liver care, naturally.',
    benefits: [
      'Promotes healthy liver function & metabolism',
      'Supports detoxification',
      'Improves digestion & appetite',
      'Protects liver cells from damage'
    ],
    dosage: '1–2 teaspoons (5–10 ml) twice daily after meals',
    ingredients: 'Himsra, Kasani, Arjuna, Punarnava, Bhringaraja, Guduchi',
  ),
  'HB+ Syrup': ProductInfo(
    tagline: 'Naturally boost your hemoglobin and energy.',
    benefits: [
      'Helps manage iron deficiency & anaemia',
      'Supports red blood cell production',
      'Provides vitamins, minerals & antioxidants',
      'Promotes liver & digestive health'
    ],
    dosage: '1–2 teaspoons (5–10 ml) twice daily after meals',
    ingredients: 'Amla, Anar, Shilajit, Mulethi, Bhui Amla',
  ),
  'Gas-O-Free Syrup': ProductInfo(
    tagline: 'Natural relief for digestion and bloating.',
    benefits: [
      'Relieves indigestion, bloating & flatulence',
      'Improves digestion & gastric secretion',
      'Eases constipation & abdominal discomfort'
    ],
    dosage: '1–2 teaspoons (5–10 ml) twice daily after meals',
    ingredients: 'Amla, Mulethi, Saunf, Nishoth, Giloe, Satavari',
  ),
  'Arogya Churn': ProductInfo(
    tagline: 'Natural relief for constipation & digestion.',
    benefits: [
      'Improves digestion & nutrient absorption',
      'Reduces bloating & flatulence',
      'Relieves constipation'
    ],
    dosage: '8–10 g with lukewarm water at bedtime',
    ingredients: 'Harad, Baheda, Amla, Kali Mirch, Pipul',
  ),
  'Go Piles Tablets': ProductInfo(
    tagline: 'Natural relief for piles & hemorrhoids.',
    benefits: [
      'Reduces pain & inflammation of piles',
      'Controls bleeding & shrinks pile mass',
      'Relieves itching & irritation',
      'Regulates bowel movements'
    ],
    dosage: '2 tablets twice or thrice daily before meals',
    ingredients: 'Bakain, Chavya, Nagkesar, Daruhaldi, Harad',
  ),
  'Gopiles Syrup': ProductInfo(
    tagline: 'Natural relief for piles & hemorrhoids.',
    benefits: [
      'Reduces pain & inflammation',
      'Controls bleeding, shrinks pile mass',
      'Supports digestion & bowel movements'
    ],
    dosage: '2–3 teaspoons (10–15 ml) twice daily',
    ingredients: 'Bakain, Chavya, Nagkesar, Daruhaldi, Harad',
  ),
  'Adicardial Tablet': ProductInfo(
    tagline: "For women's health, naturally.",
    benefits: [
      'Regulates menstrual cycles',
      'Eases cramps & abdominal pain',
      'Supports reproductive detox & immunity',
      'Reduces stress & anxiety'
    ],
    dosage: '1–2 tablets twice daily after a meal',
    ingredients: 'Ashok, Satavari, Lodhra, Guduchi, Punarnava, Ashvagandha',
  ),
  'Adicardial Syrup': ProductInfo(
    tagline: "For women's health, naturally.",
    benefits: [
      'Regulates menstrual cycles',
      'Eases cramps & spasms',
      'Blood purification & immunity',
      'Promotes vitality'
    ],
    dosage: '2–3 teaspoons (10–15 ml) twice daily',
    ingredients: 'Ashok, Satavari, Lodhra, Guduchi, Punarnava, Ashvagandha',
  ),
  'Orthofix Tablet': ProductInfo(
    tagline: 'Strong joints. Easy moves. Naturally.',
    benefits: [
      'Relieves joint stiffness & swelling',
      'Supports flexibility & movement',
      'Soothes aching muscles',
      'Enhances blood flow to joints'
    ],
    dosage: '1–2 tablets twice daily',
    ingredients: 'Ashwagandha, Guggulu, Rasna, Sonth, Punarnava',
  ),
  'Orthofix Oil': ProductInfo(
    tagline: 'Warming relief for sore joints & muscles.',
    benefits: [
      'Soothes joint & muscle pain',
      'Warming, relaxing effect',
      'Improves local circulation'
    ],
    dosage: 'Apply 3–5 ml to the affected area twice a day; massage gently',
    ingredients: 'Camphor, Peppermint, Eucalyptus, Clove & Sesame Oil',
  ),
  'Hi-Energy Tablets': ProductInfo(
    tagline: 'Naturally energized every day.',
    benefits: [
      'Increases energy & stamina',
      'Supports immune response',
      'Reduces physical & mental fatigue',
      'Adaptogens help manage stress'
    ],
    dosage: 'Take 2 tablets twice daily',
    ingredients: 'Amaltas, Mulethi, Akarakara, Utangan, Kalaunji',
  ),
  'Adilaforte Tablet': ProductInfo(
    tagline: 'Power up your confidence & vitality.',
    benefits: [
      'Supports stamina, strength & energy',
      'Promotes male vitality',
      'Helps maintain testosterone levels',
      'Aids in managing fatigue'
    ],
    dosage: '1 tablet with milk, 2 hours before activity',
    ingredients: 'Kaunch Beej, Ashwagandha, Shatavari, Gokshura, Shilajit',
  ),
  'Kidney Kawach': ProductInfo(
    tagline: 'Natural support for kidney & urinary wellness.',
    benefits: [
      'Promotes healthy urine flow',
      'Supports kidney & urinary tract',
      'Helps flush out toxins',
      'Antioxidant-rich immunity support'
    ],
    dosage: '5–15 g twice a day',
    ingredients: 'Safed Punarnava, Varuna, Gokhru, Giloe, Amla',
  ),
  'Asthprash': ProductInfo(
    tagline: 'Breathe easy. Live healthy.',
    benefits: [
      'Cleanses lungs of tar & pollutants',
      'Helps control asthma & allergy',
      'Strengthens lung tissue & breathing',
      'Boosts immunity'
    ],
    dosage: 'Adults: 1 tablespoon (15–20 g) before sleeping',
    ingredients: 'Tulsi, Mulethi, Kali Mirch, Adusa, Honey',
  ),
  'N-Astheal Tablet': ProductInfo(
    tagline: 'Breathe easy, breathe free — naturally.',
    benefits: [
      'Relieves chest congestion & phlegm',
      'Supports breathing & lung function',
      'Useful in cough, bronchitis & asthma',
      'Boosts respiratory immunity'
    ],
    dosage: '1–2 tablets twice daily',
    ingredients: 'Aragvadha, Mulethi, Akarakara, Utangan, Kalaunji',
  ),
  'Premium Tulsi Max': ProductInfo(
    tagline: 'A daily dose of wellness with the power of Tulsi.',
    benefits: [
      'Reduces cold, cough & respiratory issues',
      'Supports heart health & reduces inflammation',
      'Aids detox & digestion',
      'Antioxidant support for skin & hair'
    ],
    dosage: '3 drops in hot water or green tea, 4–5 times daily',
    ingredients: 'Blend of five Tulsi species',
  ),
  'Golden Elixir': ProductInfo(
    tagline: 'Nano-curcumin drops with superior absorption.',
    benefits: [
      'Enhances brain, heart & digestion',
      'Reduces inflammation & joint pain, aids liver detox',
      'Boosts immunity & cleanses blood',
      'Supports mood, blood sugar & wound healing'
    ],
    dosage: 'Adults (6+ yrs): 1 ml per day',
    ingredients: 'Self-emulsifying Nano Curcumin (no piperine needed)',
  ),
  'Sea Buckthorn Juice': ProductInfo(
    tagline: 'Natural boost for skin, heart & overall health.',
    benefits: [
      'Improves cholesterol (raises HDL, lowers LDL)',
      'Supports liver, skin & brain function',
      'Improves insulin sensitivity',
      'Powerful antioxidant, 18+ amino acids & Omegas'
    ],
    dosage: 'Adults: 30 ml twice daily in the morning with lukewarm water',
    ingredients: 'Sea Buckthorn (Hippophae rhamnoides)',
  ),
  'Super Rich Berry Juice': ProductInfo(
    tagline: 'A daily boost of vitality and health.',
    benefits: [
      'Enhances immunity',
      'Supports heart, liver & kidney health',
      'Antioxidant & anti-inflammatory',
      'Improves digestion, memory & sleep'
    ],
    dosage: 'Adults: 30 ml twice daily in the morning with lukewarm water',
    ingredients: 'Aloe Vera, Ashwagandha, Moringa, Triphala, Turmeric, Amla, Spirulina',
  ),
  'Nonima Juice': ProductInfo(
    tagline: 'Boost energy, build immunity.',
    benefits: [
      'Strengthens immunity',
      'Supports metabolism & weight',
      'Improves skin & cellular repair',
      'Restores energy & mental clarity'
    ],
    dosage: 'Build up to 15 ml with 300 ml water daily',
    ingredients: 'Amlaki, Noni, Guduchi, Manduki, Garcinia',
  ),
  'Aloe Vera Guava Juice': ProductInfo(
    tagline: "Nature's healing in every sip.",
    benefits: [
      'Supports digestion, relieves heartburn',
      'Helps detox the liver & metabolism',
      'Boosts immunity',
      'Rich in vitamins including B12'
    ],
    dosage: '1 cup (200–250 ml) daily, preferably empty stomach',
    ingredients: 'Aloe Vera (Aloe barbadensis) + Guava',
  ),
  'Super Food Capsule': ProductInfo(
    tagline: '31 nutrients for full-body wellness.',
    benefits: [
      'Supports heart, stamina & immunity',
      'Promotes bone strength & glowing skin',
      'Antioxidants to fight ageing',
      'Superfoods & herbs for complete wellness'
    ],
    dosage: '2 capsules daily (1 with breakfast, 1 with dinner)',
    ingredients: 'Turmeric, Whole Foods Blend, Fruit & Vegetable Blend, Calcium',
  ),
  'Omega 3-6-9 Softgel Capsules': ProductInfo(
    tagline: 'Triple power for brain, heart & health.',
    benefits: [
      'Boosts brain & heart health',
      'Supports healthy weight, reduces liver fat',
      'Enhances nutrient absorption',
      'Fights inflammation'
    ],
    dosage: 'Take 1 capsule a day',
    ingredients: 'EPA, DHA, GLA, Oleic Acid, Olive Oil, Vitamin E',
  ),
  'Calcium Tablet': ProductInfo(
    tagline: 'Strong bones, stronger you.',
    benefits: [
      'Supports bone density & joint strength',
      'Better absorption with Vitamin D3 & K2',
      'Aids RBC & DNA formation (B12, folic acid)',
      'Boosts immunity, reduces inflammation'
    ],
    dosage: '2 tablets twice a day with meals',
    ingredients: 'Calcium Citrate, Magnesium, Alfalfa, Moringa Bark',
  ),
  'Multivitamin Tablets': ProductInfo(
    tagline: 'Everyday essentials for a healthier you.',
    benefits: [
      'Amino acids & Ginseng for energy',
      'Boosts immunity & focus',
      'Supports metabolism & performance',
      'Enhances skin health & vision'
    ],
    dosage: '1 tablet daily, during or after a meal',
    ingredients: 'Ginseng, Taurine, Soya Protein Hydrolysate, Amino Acids',
  ),
  'Vital Protein': ProductInfo(
    tagline: 'Plant-powered protein for an active lifestyle.',
    benefits: [
      'Supports lean muscle & recovery',
      'Helps maintain healthy weight',
      'Strengthens bones & joints',
      'Improves stamina & daily energy'
    ],
    dosage: 'Adults: 1 scoop (10 g) up to 3 times daily',
    ingredients: 'Pea & Brown Rice Protein, DigeZyme, Electrolytes, 9 EAAs',
  ),
  'Ample Meal': ProductInfo(
    tagline: 'The ultimate meal replacement for wellness.',
    benefits: [
      'Supports weight management & fat control',
      'Reduces excess fat & cholesterol',
      'Long-lasting satiety, curbs cravings',
      'Consistent daily energy'
    ],
    dosage: '1 scoop (25 g) in 300 ml milk; replace 1–2 meals daily',
    ingredients: 'Whey Protein, Skimmed Milk, MCTs, FOS, Vitamins & Minerals',
  ),
  'Eye Elixir Drops': ProductInfo(
    tagline: 'Protect, nourish & revitalise your eyes.',
    benefits: [
      'Enhances clear vision',
      'Reduces eye fatigue, dryness & stress',
      'Protects against retinal damage'
    ],
    dosage: 'As directed by physician',
    ingredients: 'Natural ingredients + essential vitamins',
  ),
  'Eye Health++ Tablets': ProductInfo(
    tagline: 'Comprehensive daily eye care.',
    benefits: [
      'Supports eye health & clear vision',
      'Reduces fatigue & dryness',
      'Protects from blue-light damage'
    ],
    dosage: '1 tablet daily',
    ingredients: 'Eye-care herbs + essential vitamins',
  ),
  // --- Skincare (Amara Beauty / Wild Muse) ---
  'AcneX Anti-Acne Foaming Cleanser': ProductInfo(
    tagline: 'Fights acne, controls oil, soothes skin.',
    benefits: [
      'Reduces acne, pimples & blemishes',
      'Removes excess oil, deeply cleanses pores',
      'Soothes redness & irritation',
      'Supports a healthy skin barrier'
    ],
    dosage: 'Massage onto wet face in circles, rinse; morning & evening',
    ingredients: 'Salicylic Acid 2%, Green Tea, Aloe Vera, Allantoin',
  ),
  'Deep Cleansing Face Wash': ProductInfo(
    tagline: 'Deep clean, refreshed skin.',
    benefits: [
      'Removes dirt & impurities',
      'Exfoliates dead skin cells',
      'Prevents acne & breakouts',
      'Improves skin texture'
    ],
    dosage: 'Massage on wet face, rinse; daily',
  ),
  'Anti-Pollution Aloe Vera Face Wash': ProductInfo(
    tagline: 'Shields skin from pollution damage.',
    benefits: [
      'Removes pollutants & impurities',
      'Hydrates & soothes',
      'Restores natural glow'
    ],
    dosage: 'Massage on wet face, rinse; daily',
  ),
  'Haldi Chandan Face Wash': ProductInfo(
    tagline: 'Brightening turmeric–sandalwood cleanse.',
    benefits: [
      'Helps reduce acne spots',
      'Brightens skin tone',
      'Gently cleanses impurities'
    ],
    dosage: 'Massage on wet face, rinse; daily',
  ),
  'Sea Buckthorn Cleanser': ProductInfo(
    tagline: 'Deep cleansing without drying.',
    benefits: [
      'Balances skin\'s natural oils',
      'Supports a healthy skin barrier',
      'Anti-aging & rejuvenating'
    ],
    dosage: 'Massage on damp skin, rinse; daily',
  ),
  'Face Serum (Niacinamide + Hyaluronic Acid)': ProductInfo(
    tagline: 'Glow deep. Repair naturally.',
    benefits: [
      'Hydrates & plumps with hyaluronic acid',
      'Fades dark spots & evens tone (niacinamide)',
      'Refines pores & controls oil',
      'Reduces fine lines, brightens complexion'
    ],
    dosage: 'Apply 2–3 drops on damp face & neck, twice daily',
    ingredients: 'Niacinamide, Hyaluronic Acid, Aloe Vera, Vitamin B5, Green Tea',
  ),
  'Hydra Max Gel Moisturizer': ProductInfo(
    tagline: 'Light. Cool. Hydrated.',
    benefits: [
      'Instantly hydrates dull, tired skin',
      'Soothes & cools with aloe vera',
      'Balances oil without clogging pores',
      'Improves elasticity & texture'
    ],
    dosage: 'Apply to face & neck, morning & night',
    ingredients: 'Hyaluronic Acid, Glycerin, Aloe Vera, Panthenol',
  ),
  'AgeX Night Cream': ProductInfo(
    tagline: 'Overnight anti-aging repair.',
    benefits: [
      'Reduces fine lines & wrinkles',
      'Deeply hydrates & plumps overnight',
      'Strengthens skin barrier',
      'Improves firmness & radiance'
    ],
    dosage: 'Apply nightly on cleansed face & neck, massage upward',
    ingredients: 'Retinol Palmitate, Ceramide-3, Hyaluronic Acid, Niacinamide, Copper Peptides',
  ),
  'Sunscreen SPF 50+': ProductInfo(
    tagline: 'Glow smart. Shield strong.',
    benefits: [
      'Protects from UVA & UVB rays',
      'Prevents dark spots & tanning',
      'Brightens with a dewy glow',
      'Hydrates without greasiness'
    ],
    dosage: 'Apply each morning; reapply every 2–3 hrs',
    ingredients: 'Vitamin C, Vitamin E, Glycerin, Zinc Oxide, Aloe Vera',
  ),
  'Aloe Vera Gel': ProductInfo(
    tagline: 'Soothing multi-use skin gel.',
    benefits: [
      'Reduces acne & pimples',
      'Soothes sunburn & irritation',
      'Antioxidant & anti-inflammatory',
      'Reduces fine lines'
    ],
    dosage: 'Apply a thin layer as needed',
  ),
  'Sea Buckthorn Facial Fluid': ProductInfo(
    tagline: 'Anti-aging glow fluid.',
    benefits: [
      'Intense hydration',
      'Brightens & revitalises',
      'Lightweight, non-greasy'
    ],
    dosage: 'A few drops massaged into skin',
  ),
  'Daily Care Cream': ProductInfo(
    tagline: 'Lightweight everyday day cream.',
    benefits: [
      'Evens skin tone',
      'Soothes & calms skin',
      'Prevents premature aging',
      'Protects from environmental stress'
    ],
    dosage: 'Apply on face as a light day cream',
  ),
  'Neem & Aloe Vera Soap': ProductInfo(
    tagline: 'Herbal cleansing for clearer skin.',
    benefits: [
      'Fights acne & pimples',
      'Natural detoxification',
      'Moisturizes & hydrates',
      'Gentle on sensitive skin'
    ],
    dosage: 'Use to cleanse face & body, daily',
  ),
  'Luxury Saffron Soap': ProductInfo(
    tagline: 'Saffron glow for dull skin.',
    benefits: [
      'Revitalizes dull skin',
      'Enhances skin brightness',
      'Suitable for all skin types',
      'Protects against environmental stress'
    ],
    dosage: 'Use to cleanse face & body, daily',
  ),
  'Hydra Aloe Vera Body Lotion': ProductInfo(
    tagline: 'Intense moisture for dry skin.',
    benefits: [
      'Provides intense moisture to dry skin',
      'Soothes irritated skin',
      'Maintains skin softness',
      'Protects against environmental damage'
    ],
    dosage: 'Apply to the body, especially after bathing',
  ),
};

// ===========================================================================
// Skin analysis: concerns → Dayjoy skincare (cleanse/tone/moisturize) +
// supplements. The user picks what they notice on a face photo; the doctor
// reviews & approves.
// ===========================================================================

const List<String> kSkinConcerns = [
  'Acne / pimples',
  'Blemishes / dark spots',
  'Dark circles',
  'Wrinkles / fine lines',
  'Dryness',
  'Oily skin',
  'Dullness',
  'Open pores',
  'Pigmentation / uneven tone',
  'Sensitivity / redness',
  'Body dryness',
];

const List<String> kSkincareEat = [
  'Plenty of water (8–12 glasses/day)',
  'Vitamin A, C & E rich fruits & vegetables',
  'Omega-3 foods (fish, flax, walnuts)',
  'Leafy greens & antioxidants',
];
const List<String> kSkincareAvoid = [
  'Fried & oily food',
  'Excess sugar & sweets',
  'Coffee & fizzy drinks',
  'Processed & smoked foods',
];

/// Concern → recommended Dayjoy products (skincare + supplement support).
const Map<String, List<String>> kSkinRules = {
  'Acne / pimples': [
    'AcneX Anti-Acne Foaming Cleanser',
    'Neem & Aloe Vera Soap',
    'Aloe Vera Gel',
    'Hydra Max Gel Moisturizer',
    'Aloe Vera Guava Juice',
    'Golden Elixir',
  ],
  'Blemishes / dark spots': [
    'Haldi Chandan Face Wash',
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Sunscreen SPF 50+',
    'Super Rich Berry Juice',
  ],
  'Dark circles': [
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Hydra Max Gel Moisturizer',
    'Sea Buckthorn Juice',
    'Multivitamin Tablets',
  ],
  'Wrinkles / fine lines': [
    'AgeX Night Cream',
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Sea Buckthorn Facial Fluid',
    'Omega 3-6-9 Softgel Capsules',
    'Golden Elixir',
  ],
  'Dryness': [
    'Anti-Pollution Aloe Vera Face Wash',
    'Hydra Max Gel Moisturizer',
    'Sea Buckthorn Facial Fluid',
    'Omega 3-6-9 Softgel Capsules',
  ],
  'Oily skin': [
    'AcneX Anti-Acne Foaming Cleanser',
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Hydra Max Gel Moisturizer',
  ],
  'Dullness': [
    'Luxury Saffron Soap',
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Daily Care Cream',
    'Super Rich Berry Juice',
    'Sea Buckthorn Juice',
  ],
  'Open pores': [
    'AcneX Anti-Acne Foaming Cleanser',
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Hydra Max Gel Moisturizer',
  ],
  'Pigmentation / uneven tone': [
    'Haldi Chandan Face Wash',
    'Face Serum (Niacinamide + Hyaluronic Acid)',
    'Daily Care Cream',
    'Sunscreen SPF 50+',
    'Golden Elixir',
  ],
  'Sensitivity / redness': [
    'Anti-Pollution Aloe Vera Face Wash',
    'Aloe Vera Gel',
    'Daily Care Cream',
    'Hydra Max Gel Moisturizer',
  ],
  'Body dryness': [
    'Hydra Aloe Vera Body Lotion',
    'Aloe Vera Gel',
    'Omega 3-6-9 Softgel Capsules',
    'Sea Buckthorn Juice',
  ],
};

/// Best dosage for a product — prefers the brochure's "how to consume".
String dosageFor(String product) =>
    kProductInfo[product]?.dosage ?? kProductDosage[product] ?? '1 dose daily';

/// Product knowledge (or null if we don't have a brochure entry).
ProductInfo? infoFor(String product) => kProductInfo[product];
