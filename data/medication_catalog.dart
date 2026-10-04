/// Offline catalog of common medications used for search suggestions.
///
/// This list exists only to make typing easier. It is not medical advice,
/// and strengths shown are common label strengths, not recommendations.
class CatalogMedication {
  const CatalogMedication(this.name, this.strengths);

  final String name;
  final List<String> strengths;
}

class MedicationCatalog {
  MedicationCatalog._();

  /// Returns up to [limit] medication names matching [query].
  /// Names that start with the query rank above names that merely contain it.
  static List<String> search(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final startsWith = <String>[];
    final contains = <String>[];
    for (final med in all) {
      final name = med.name.toLowerCase();
      if (name.startsWith(q)) {
        startsWith.add(med.name);
      } else if (name.contains(q)) {
        contains.add(med.name);
      }
    }
    return [...startsWith, ...contains].take(limit).toList();
  }

  /// Common strengths for [name], or an empty list if unknown.
  static List<String> strengthsFor(String name) {
    final n = name.trim().toLowerCase();
    for (final med in all) {
      if (med.name.toLowerCase() == n) return med.strengths;
    }
    return const [];
  }

  /// Generic strength options offered when the medication is not in the catalog.
  static const List<String> genericStrengths = [
    '5 mg',
    '10 mg',
    '20 mg',
    '25 mg',
    '50 mg',
    '100 mg',
    '250 mg',
    '500 mg',
    '1000 mg',
  ];

  /// Common dose options.
  static const List<String> doseOptions = [
    '1 tablet',
    '2 tablets',
    '1/2 tablet',
    '1 capsule',
    '2 capsules',
    '1 puff',
    '2 puffs',
    '1 patch',
    '1 injection',
    '5 mL',
    '10 mL',
    '1 drop',
    '2 drops',
  ];

  /// Common time-of-day / schedule options.
  static const List<String> scheduleOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Bedtime',
    'Morning and evening',
    'With meals',
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every other day',
    'Once weekly',
    'As needed',
  ];

  static const List<CatalogMedication> all = [
    // Blood pressure / heart
    CatalogMedication('Lisinopril', [
      '2.5 mg',
      '5 mg',
      '10 mg',
      '20 mg',
      '30 mg',
      '40 mg',
    ]),
    CatalogMedication('Amlodipine', ['2.5 mg', '5 mg', '10 mg']),
    CatalogMedication('Amlodipine (Norvasc)', ['2.5 mg', '5 mg', '10 mg']),
    CatalogMedication('Losartan', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Losartan (Cozaar)', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Metoprolol succinate (Toprol-XL)', [
      '25 mg',
      '50 mg',
      '100 mg',
      '200 mg',
    ]),
    CatalogMedication('Metoprolol tartrate (Lopressor)', [
      '25 mg',
      '50 mg',
      '100 mg',
    ]),
    CatalogMedication('Atenolol', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Carvedilol', [
      '3.125 mg',
      '6.25 mg',
      '12.5 mg',
      '25 mg',
    ]),
    CatalogMedication('Hydrochlorothiazide', ['12.5 mg', '25 mg', '50 mg']),
    CatalogMedication('Furosemide (Lasix)', ['20 mg', '40 mg', '80 mg']),
    CatalogMedication('Spironolactone', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Valsartan (Diovan)', [
      '40 mg',
      '80 mg',
      '160 mg',
      '320 mg',
    ]),
    CatalogMedication('Olmesartan (Benicar)', ['5 mg', '20 mg', '40 mg']),
    CatalogMedication('Clonidine', ['0.1 mg', '0.2 mg', '0.3 mg']),
    CatalogMedication('Diltiazem', [
      '30 mg',
      '60 mg',
      '90 mg',
      '120 mg',
      '180 mg',
      '240 mg',
    ]),
    CatalogMedication('Propranolol', ['10 mg', '20 mg', '40 mg', '80 mg']),
    // Cholesterol
    CatalogMedication('Atorvastatin (Lipitor)', [
      '10 mg',
      '20 mg',
      '40 mg',
      '80 mg',
    ]),
    CatalogMedication('Simvastatin (Zocor)', [
      '5 mg',
      '10 mg',
      '20 mg',
      '40 mg',
    ]),
    CatalogMedication('Rosuvastatin (Crestor)', [
      '5 mg',
      '10 mg',
      '20 mg',
      '40 mg',
    ]),
    CatalogMedication('Pravastatin', ['10 mg', '20 mg', '40 mg', '80 mg']),
    CatalogMedication('Ezetimibe (Zetia)', ['10 mg']),
    CatalogMedication('Fenofibrate', ['48 mg', '145 mg']),
    // Diabetes
    CatalogMedication('Metformin', ['500 mg', '850 mg', '1000 mg']),
    CatalogMedication('Metformin ER (Glucophage XR)', [
      '500 mg',
      '750 mg',
      '1000 mg',
    ]),
    CatalogMedication('Glipizide', ['2.5 mg', '5 mg', '10 mg']),
    CatalogMedication('Glimepiride', ['1 mg', '2 mg', '4 mg']),
    CatalogMedication('Sitagliptin (Januvia)', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Empagliflozin (Jardiance)', ['10 mg', '25 mg']),
    CatalogMedication('Dapagliflozin (Farxiga)', ['5 mg', '10 mg']),
    CatalogMedication('Semaglutide (Ozempic)', [
      '0.25 mg',
      '0.5 mg',
      '1 mg',
      '2 mg',
    ]),
    CatalogMedication('Semaglutide (Wegovy)', [
      '0.25 mg',
      '0.5 mg',
      '1 mg',
      '1.7 mg',
      '2.4 mg',
    ]),
    CatalogMedication('Liraglutide (Victoza)', ['0.6 mg', '1.2 mg', '1.8 mg']),
    CatalogMedication('Tirzepatide (Mounjaro)', [
      '2.5 mg',
      '5 mg',
      '7.5 mg',
      '10 mg',
      '12.5 mg',
      '15 mg',
    ]),
    CatalogMedication('Insulin glargine (Lantus)', ['100 units/mL']),
    CatalogMedication('Insulin lispro (Humalog)', ['100 units/mL']),
    CatalogMedication('Insulin aspart (Novolog)', ['100 units/mL']),
    // Thyroid
    CatalogMedication('Levothyroxine (Synthroid)', [
      '25 mcg',
      '50 mcg',
      '75 mcg',
      '88 mcg',
      '100 mcg',
      '112 mcg',
      '125 mcg',
      '137 mcg',
      '150 mcg',
      '175 mcg',
      '200 mcg',
    ]),
    CatalogMedication('Methimazole', ['5 mg', '10 mg']),
    // Stomach / reflux
    CatalogMedication('Omeprazole (Prilosec)', ['10 mg', '20 mg', '40 mg']),
    CatalogMedication('Esomeprazole (Nexium)', ['20 mg', '40 mg']),
    CatalogMedication('Pantoprazole (Protonix)', ['20 mg', '40 mg']),
    CatalogMedication('Famotidine (Pepcid)', ['10 mg', '20 mg', '40 mg']),
    CatalogMedication('Ondansetron (Zofran)', ['4 mg', '8 mg']),
    CatalogMedication('Sucralfate', ['1 g']),
    // Mental health
    CatalogMedication('Sertraline (Zoloft)', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Escitalopram (Lexapro)', ['5 mg', '10 mg', '20 mg']),
    CatalogMedication('Fluoxetine (Prozac)', ['10 mg', '20 mg', '40 mg']),
    CatalogMedication('Citalopram (Celexa)', ['10 mg', '20 mg', '40 mg']),
    CatalogMedication('Paroxetine (Paxil)', [
      '10 mg',
      '20 mg',
      '30 mg',
      '40 mg',
    ]),
    CatalogMedication('Bupropion (Wellbutrin XL)', ['150 mg', '300 mg']),
    CatalogMedication('Venlafaxine (Effexor XR)', [
      '37.5 mg',
      '75 mg',
      '150 mg',
    ]),
    CatalogMedication('Duloxetine (Cymbalta)', ['20 mg', '30 mg', '60 mg']),
    CatalogMedication('Trazodone', ['50 mg', '100 mg', '150 mg']),
    CatalogMedication('Mirtazapine (Remeron)', [
      '7.5 mg',
      '15 mg',
      '30 mg',
      '45 mg',
    ]),
    CatalogMedication('Buspirone', [
      '5 mg',
      '7.5 mg',
      '10 mg',
      '15 mg',
      '30 mg',
    ]),
    CatalogMedication('Alprazolam (Xanax)', [
      '0.25 mg',
      '0.5 mg',
      '1 mg',
      '2 mg',
    ]),
    CatalogMedication('Lorazepam (Ativan)', ['0.5 mg', '1 mg', '2 mg']),
    CatalogMedication('Quetiapine (Seroquel)', [
      '25 mg',
      '50 mg',
      '100 mg',
      '200 mg',
      '300 mg',
    ]),
    CatalogMedication('Aripiprazole (Abilify)', [
      '2 mg',
      '5 mg',
      '10 mg',
      '15 mg',
      '20 mg',
      '30 mg',
    ]),
    CatalogMedication('Lamotrigine (Lamictal)', [
      '25 mg',
      '100 mg',
      '150 mg',
      '200 mg',
    ]),
    CatalogMedication('Lithium carbonate', ['150 mg', '300 mg', '600 mg']),
    // ADHD
    CatalogMedication('Methylphenidate (Ritalin)', ['5 mg', '10 mg', '20 mg']),
    CatalogMedication('Methylphenidate ER (Concerta)', [
      '18 mg',
      '27 mg',
      '36 mg',
      '54 mg',
    ]),
    CatalogMedication('Amphetamine salts (Adderall)', [
      '5 mg',
      '10 mg',
      '15 mg',
      '20 mg',
      '30 mg',
    ]),
    CatalogMedication('Amphetamine salts XR (Adderall XR)', [
      '5 mg',
      '10 mg',
      '15 mg',
      '20 mg',
      '25 mg',
      '30 mg',
    ]),
    CatalogMedication('Lisdexamfetamine (Vyvanse)', [
      '10 mg',
      '20 mg',
      '30 mg',
      '40 mg',
      '50 mg',
      '60 mg',
      '70 mg',
    ]),
    CatalogMedication('Atomoxetine (Strattera)', [
      '10 mg',
      '18 mg',
      '25 mg',
      '40 mg',
      '60 mg',
      '80 mg',
      '100 mg',
    ]),
    // Pain / inflammation
    CatalogMedication('Acetaminophen (Tylenol)', [
      '325 mg',
      '500 mg',
      '650 mg',
    ]),
    CatalogMedication('Ibuprofen (Advil, Motrin)', [
      '200 mg',
      '400 mg',
      '600 mg',
      '800 mg',
    ]),
    CatalogMedication('Naproxen (Aleve)', [
      '220 mg',
      '250 mg',
      '375 mg',
      '500 mg',
    ]),
    CatalogMedication('Aspirin', ['81 mg', '325 mg']),
    CatalogMedication('Meloxicam (Mobic)', ['7.5 mg', '15 mg']),
    CatalogMedication('Celecoxib (Celebrex)', ['100 mg', '200 mg']),
    CatalogMedication('Diclofenac', ['50 mg', '75 mg']),
    CatalogMedication('Tramadol (Ultram)', ['50 mg', '100 mg']),
    CatalogMedication('Gabapentin (Neurontin)', [
      '100 mg',
      '300 mg',
      '400 mg',
      '600 mg',
      '800 mg',
    ]),
    CatalogMedication('Pregabalin (Lyrica)', [
      '25 mg',
      '50 mg',
      '75 mg',
      '100 mg',
      '150 mg',
      '300 mg',
    ]),
    CatalogMedication('Cyclobenzaprine (Flexeril)', ['5 mg', '10 mg']),
    CatalogMedication('Tizanidine (Zanaflex)', ['2 mg', '4 mg']),
    CatalogMedication('Sumatriptan (Imitrex)', ['25 mg', '50 mg', '100 mg']),
    // Allergy / respiratory
    CatalogMedication('Cetirizine (Zyrtec)', ['5 mg', '10 mg']),
    CatalogMedication('Loratadine (Claritin)', ['10 mg']),
    CatalogMedication('Fexofenadine (Allegra)', ['60 mg', '120 mg', '180 mg']),
    CatalogMedication('Diphenhydramine (Benadryl)', ['25 mg', '50 mg']),
    CatalogMedication('Montelukast (Singulair)', ['4 mg', '5 mg', '10 mg']),
    CatalogMedication('Fluticasone nasal spray (Flonase)', ['50 mcg/spray']),
    CatalogMedication('Albuterol inhaler (ProAir, Ventolin)', ['90 mcg/puff']),
    CatalogMedication('Budesonide-formoterol (Symbicort)', [
      '80/4.5 mcg',
      '160/4.5 mcg',
    ]),
    CatalogMedication('Fluticasone-salmeterol (Advair)', [
      '100/50 mcg',
      '250/50 mcg',
      '500/50 mcg',
    ]),
    CatalogMedication('Tiotropium (Spiriva)', ['18 mcg', '2.5 mcg/puff']),
    CatalogMedication('Prednisone', [
      '1 mg',
      '2.5 mg',
      '5 mg',
      '10 mg',
      '20 mg',
      '50 mg',
    ]),
    // Antibiotics
    CatalogMedication('Amoxicillin', ['250 mg', '500 mg', '875 mg']),
    CatalogMedication('Amoxicillin-clavulanate (Augmentin)', [
      '500/125 mg',
      '875/125 mg',
    ]),
    CatalogMedication('Azithromycin (Zithromax, Z-Pak)', ['250 mg', '500 mg']),
    CatalogMedication('Cephalexin (Keflex)', ['250 mg', '500 mg']),
    CatalogMedication('Ciprofloxacin (Cipro)', ['250 mg', '500 mg', '750 mg']),
    CatalogMedication('Doxycycline', ['50 mg', '100 mg']),
    CatalogMedication('Nitrofurantoin (Macrobid)', ['100 mg']),
    CatalogMedication('Trimethoprim-sulfamethoxazole (Bactrim)', [
      '400/80 mg',
      '800/160 mg',
    ]),
    CatalogMedication('Metronidazole (Flagyl)', ['250 mg', '500 mg']),
    CatalogMedication('Clindamycin', ['150 mg', '300 mg']),
    CatalogMedication('Valacyclovir (Valtrex)', ['500 mg', '1000 mg']),
    CatalogMedication('Fluconazole (Diflucan)', ['100 mg', '150 mg', '200 mg']),
    // Blood thinners
    CatalogMedication('Warfarin (Coumadin)', [
      '1 mg',
      '2 mg',
      '2.5 mg',
      '3 mg',
      '4 mg',
      '5 mg',
      '7.5 mg',
      '10 mg',
    ]),
    CatalogMedication('Apixaban (Eliquis)', ['2.5 mg', '5 mg']),
    CatalogMedication('Rivaroxaban (Xarelto)', ['10 mg', '15 mg', '20 mg']),
    CatalogMedication('Clopidogrel (Plavix)', ['75 mg']),
    // Sleep
    CatalogMedication('Melatonin', ['1 mg', '3 mg', '5 mg', '10 mg']),
    CatalogMedication('Zolpidem (Ambien)', ['5 mg', '10 mg']),
    // Bone / vitamins / supplements
    CatalogMedication('Alendronate (Fosamax)', ['35 mg', '70 mg']),
    CatalogMedication('Vitamin D3 (cholecalciferol)', [
      '400 IU',
      '1000 IU',
      '2000 IU',
      '5000 IU',
      '50000 IU',
    ]),
    CatalogMedication('Vitamin B12 (cyanocobalamin)', ['500 mcg', '1000 mcg']),
    CatalogMedication('Folic acid', ['400 mcg', '800 mcg', '1 mg']),
    CatalogMedication('Ferrous sulfate (iron)', ['325 mg']),
    CatalogMedication('Calcium carbonate', ['500 mg', '600 mg']),
    CatalogMedication('Magnesium oxide', ['250 mg', '400 mg', '500 mg']),
    CatalogMedication('Fish oil (omega-3)', ['1000 mg']),
    CatalogMedication('Multivitamin', []),
    CatalogMedication('Potassium chloride', ['10 mEq', '20 mEq']),
    // Urology / hormones
    CatalogMedication('Tamsulosin (Flomax)', ['0.4 mg']),
    CatalogMedication('Finasteride (Proscar, Propecia)', ['1 mg', '5 mg']),
    CatalogMedication('Sildenafil (Viagra)', ['25 mg', '50 mg', '100 mg']),
    CatalogMedication('Tadalafil (Cialis)', [
      '2.5 mg',
      '5 mg',
      '10 mg',
      '20 mg',
    ]),
    CatalogMedication('Estradiol', ['0.5 mg', '1 mg', '2 mg']),
    CatalogMedication('Norethindrone-ethinyl estradiol (birth control)', []),
    CatalogMedication('Oxybutynin', ['5 mg', '10 mg']),
    // Gout / misc
    CatalogMedication('Allopurinol', ['100 mg', '300 mg']),
    CatalogMedication('Colchicine (Colcrys)', ['0.6 mg']),
    CatalogMedication('Hydroxyzine', ['10 mg', '25 mg', '50 mg']),
    CatalogMedication('Hydroxychloroquine (Plaquenil)', ['200 mg']),
    CatalogMedication('Methotrexate', ['2.5 mg', '7.5 mg', '10 mg', '15 mg']),
    CatalogMedication('Levetiracetam (Keppra)', [
      '250 mg',
      '500 mg',
      '750 mg',
      '1000 mg',
    ]),
    CatalogMedication('Topiramate (Topamax)', [
      '25 mg',
      '50 mg',
      '100 mg',
      '200 mg',
    ]),
    CatalogMedication('Donepezil (Aricept)', ['5 mg', '10 mg']),
    CatalogMedication('Ropinirole (Requip)', [
      '0.25 mg',
      '0.5 mg',
      '1 mg',
      '2 mg',
    ]),
  ];
}
