import Foundation

// Custom units
extension UnitPressure {
  static let standardAtmospheres = UnitPressure(
    symbol: "atm",
    converter: UnitConverterLinear(coefficient: 101325)
  )
}

// Helpers
extension String {
  func removingPrefixes(_ prefixes: [String]) -> String {
    for prefix in prefixes {
      if self.hasPrefix(prefix) { return String(self.dropFirst(prefix.count)) }
    }

    return self
  }
}

struct ScriptFilterItem: Codable {
  let uid: String
  let title: String
  let subtitle: String
  let autocomplete: String?
  let arg: String?
  let valid: Bool
}

struct MeasureInfo {
  let names: [String]
  let symbol: String
  let unit: Dimension

  init(names: [String], unit: Dimension, imperial: Bool = false) {
    self.names = names
    self.symbol = imperial ? "imperial \(unit.symbol)" : unit.symbol
    self.unit = unit
  }

  // Handle matching
  enum MatchType {
    case none, partial, exact
  }

  func matches(_ searchTerm: String) -> MatchType {
    // Check for sumbol matches
    let matchSymbol = self.symbol.hasPrefix(searchTerm)

    if matchSymbol {
      if self.symbol == searchTerm { return .exact }
      return .partial
    }

    // Check for name matches
    let matchNames = self.names.filter { $0.hasPrefix(searchTerm) }

    if matchNames.count > 0 {
      if (matchNames.contains { $0 == searchTerm }) { return .exact }
      return .partial
    }

    // Nothing matches
    return .none
  }
}

struct FormatMeasure {
  let string: String

  static let formatter: NumberFormatter = {
    let env: [String: String] = ProcessInfo.processInfo.environment
    let formatter: NumberFormatter = NumberFormatter()

    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = Int(env["decimal_places"]!)!
    return formatter
  }()

  init(value: Double, measure: MeasureInfo) {
    let valueString: String =
      FormatMeasure.formatter.string(from: value as NSNumber)
      ?? String(value)
    self.string = "\(valueString) \(measure.symbol)"
  }
}

func matchMeasures(from searchString: String, in measures: [MeasureInfo]) -> [(measure: MeasureInfo, matchedChars: Int)] {
  let splitSearch = searchString.split(separator: " ")

  // Keep removing the last word on a loop until any match is found
  for wordIndex in stride(from: splitSearch.count - 1, through: 0, by: -1) {
    let currentString = splitSearch[0...wordIndex].joined(separator: " ")

    // Filter for matches and return them with the information on if they are partial or exact
    let matchingMeasures = measures.compactMap { measure -> (measure: MeasureInfo, matching: MeasureInfo.MatchType)? in
      let matchType = measure.matches(currentString)
      if matchType == .none { return nil }
      return (measure: measure, matching: matchType)
    }

    // Number of characters matched
    let matchedChars = currentString.count

    // If something matches exactly, output it on its own
    if let exactMatch = matchingMeasures.first(where: { $0.matching == .exact }) {
      return [(measure: exactMatch.measure, matchedChars: matchedChars)]
    }

    // If there are ambiguous matches, output them all
    // Sorted by smallest unit, which is more likely to be a more common one
    if matchingMeasures.count > 0 {
      return matchingMeasures
        .sorted { $0.measure.symbol.count < $1.measure.symbol.count }
        .map { (measure: $0.measure, matchedChars: matchedChars) }
    }
  }

  // Nothing found
  return []
}

func showItems(_ sfItems: [ScriptFilterItem]) {
  let jsonData = try! JSONEncoder().encode(["items": sfItems])
  print(String(data: jsonData, encoding: .utf8)!)
}

let allMeasures: [MeasureInfo] = [
  // Not Included:
  // * UnitAcceleration, as it only has two methods and the symbols of gravity and grams clash:
  //   https://developer.apple.com/documentation/foundation/unitacceleration
  // * UnitConcentrationMass.millimolesPerLiter(withGramsPerMole:) as it requires an argument:
  //   https://developer.apple.com/documentation/foundation/unitconcentrationmass/1855799-millimolesperliter
  // * UnitDispersion, as it only has one method:
  //   https://developer.apple.com/documentation/foundation/unitdispersion
  // * UnitIlluminance, as it only has one method:
  //   https://developer.apple.com/documentation/foundation/unitilluminance

  // Angle
  MeasureInfo(names: ["degrees"], unit: UnitAngle.degrees),
  MeasureInfo(names: ["arc minutes"], unit: UnitAngle.arcMinutes),
  MeasureInfo(names: ["arc seconds"], unit: UnitAngle.arcSeconds),
  MeasureInfo(names: ["radians"], unit: UnitAngle.radians),
  MeasureInfo(names: ["gradians"], unit: UnitAngle.gradians),
  MeasureInfo(names: ["revolutions"], unit: UnitAngle.revolutions),

  // Area
  MeasureInfo(names: ["square megameters"], unit: UnitArea.squareMegameters),
  MeasureInfo(names: ["square kilometers"], unit: UnitArea.squareKilometers),
  MeasureInfo(names: ["square meters"], unit: UnitArea.squareMeters),
  MeasureInfo(names: ["square centimeters"], unit: UnitArea.squareCentimeters),
  MeasureInfo(names: ["square millimiters"], unit: UnitArea.squareMillimeters),
  MeasureInfo(names: ["square micrometers"], unit: UnitArea.squareMicrometers),
  MeasureInfo(names: ["square nanometers"], unit: UnitArea.squareNanometers),
  MeasureInfo(names: ["square inches"], unit: UnitArea.squareInches),
  MeasureInfo(names: ["square feet"], unit: UnitArea.squareFeet),
  MeasureInfo(names: ["square yards"], unit: UnitArea.squareYards),
  MeasureInfo(names: ["square miles"], unit: UnitArea.squareMiles),
  MeasureInfo(names: ["acres"], unit: UnitArea.acres),
  MeasureInfo(names: ["ares"], unit: UnitArea.ares),
  MeasureInfo(names: ["hectares"], unit: UnitArea.hectares),

  // Concentration of Mass
  MeasureInfo(names: ["grams per liter"], unit: UnitConcentrationMass.gramsPerLiter),
  MeasureInfo(names: ["milligrams per deciliter"], unit: UnitConcentrationMass.milligramsPerDeciliter),

  // Duration
  MeasureInfo(names: ["seconds"], unit: UnitDuration.seconds),
  MeasureInfo(names: ["minutes"], unit: UnitDuration.minutes),
  MeasureInfo(names: ["hours"], unit: UnitDuration.hours),

  // Electric Charge
  MeasureInfo(names: ["coulombs"], unit: UnitElectricCharge.coulombs),
  MeasureInfo(names: ["megaampere hours"], unit: UnitElectricCharge.megaampereHours),
  MeasureInfo(names: ["kiloampere hours"], unit: UnitElectricCharge.kiloampereHours),
  MeasureInfo(names: ["ampere hours"], unit: UnitElectricCharge.ampereHours),
  MeasureInfo(names: ["milliampere hours"], unit: UnitElectricCharge.milliampereHours),
  MeasureInfo(names: ["microampere hours"], unit: UnitElectricCharge.microampereHours),

  // Electric Current
  MeasureInfo(names: ["megaamperes"], unit: UnitElectricCurrent.megaamperes),
  MeasureInfo(names: ["kiloamperes"], unit: UnitElectricCurrent.kiloamperes),
  MeasureInfo(names: ["amperes"], unit: UnitElectricCurrent.amperes),
  MeasureInfo(names: ["milliamperes"], unit: UnitElectricCurrent.milliamperes),
  MeasureInfo(names: ["microamperes"], unit: UnitElectricCurrent.microamperes),

  // Electric Potential Difference
  MeasureInfo(names: ["megavolts"], unit: UnitElectricPotentialDifference.megavolts),
  MeasureInfo(names: ["kilovolts"], unit: UnitElectricPotentialDifference.kilovolts),
  MeasureInfo(names: ["volts"], unit: UnitElectricPotentialDifference.volts),
  MeasureInfo(names: ["millivolts"], unit: UnitElectricPotentialDifference.millivolts),
  MeasureInfo(names: ["microvolts"], unit: UnitElectricPotentialDifference.microvolts),

  // Electric Resistance
  MeasureInfo(names: ["megaohms"], unit: UnitElectricResistance.megaohms),
  MeasureInfo(names: ["kiloohms"], unit: UnitElectricResistance.kiloohms),
  MeasureInfo(names: ["ohms"], unit: UnitElectricResistance.ohms),
  MeasureInfo(names: ["milliohms"], unit: UnitElectricResistance.milliohms),
  MeasureInfo(names: ["microohms"], unit: UnitElectricResistance.microohms),

  // Energy
  MeasureInfo(names: ["kilojoules"], unit: UnitEnergy.kilojoules),
  MeasureInfo(names: ["joules"], unit: UnitEnergy.joules),
  MeasureInfo(names: ["kilocalories"], unit: UnitEnergy.kilocalories),
  MeasureInfo(names: ["calories"], unit: UnitEnergy.calories),
  MeasureInfo(names: ["kilowatt hours"], unit: UnitEnergy.kilowattHours),

  // Frequency
  MeasureInfo(names: ["terahertz"], unit: UnitFrequency.terahertz),
  MeasureInfo(names: ["gigahertz"], unit: UnitFrequency.gigahertz),
  MeasureInfo(names: ["megahertz"], unit: UnitFrequency.megahertz),
  MeasureInfo(names: ["kilohertz"], unit: UnitFrequency.kilohertz),
  MeasureInfo(names: ["hertz"], unit: UnitFrequency.hertz),
  MeasureInfo(names: ["millihertz"], unit: UnitFrequency.millihertz),
  MeasureInfo(names: ["microhertz"], unit: UnitFrequency.microhertz),
  MeasureInfo(names: ["nanohertz"], unit: UnitFrequency.nanohertz),

  // Fuel Efficiency
  MeasureInfo(names: ["liters per 100 kilometers"], unit: UnitFuelEfficiency.litersPer100Kilometers),
  MeasureInfo(names: ["miles per gallon"], unit: UnitFuelEfficiency.milesPerGallon),
  MeasureInfo(names: ["miles per imperial gallon"], unit: UnitFuelEfficiency.milesPerImperialGallon, imperial: true),

  // Information Storage
  MeasureInfo(names: ["nibbles"], unit: UnitInformationStorage.nibbles),
  MeasureInfo(names: ["bits"], unit: UnitInformationStorage.bits),
  MeasureInfo(names: ["bytes"], unit: UnitInformationStorage.bytes),

  MeasureInfo(names: ["kilobits"], unit: UnitInformationStorage.kilobits),
  MeasureInfo(names: ["megabits"], unit: UnitInformationStorage.megabits),
  MeasureInfo(names: ["gigabits"], unit: UnitInformationStorage.gigabits),
  MeasureInfo(names: ["terabits"], unit: UnitInformationStorage.terabits),
  MeasureInfo(names: ["petabits"], unit: UnitInformationStorage.petabits),
  MeasureInfo(names: ["exabits"], unit: UnitInformationStorage.exabits),
  MeasureInfo(names: ["zettabits"], unit: UnitInformationStorage.zettabits),
  MeasureInfo(names: ["yottabits"], unit: UnitInformationStorage.yottabits),

  MeasureInfo(names: ["kibibits"], unit: UnitInformationStorage.kibibits),
  MeasureInfo(names: ["mebibits"], unit: UnitInformationStorage.mebibits),
  MeasureInfo(names: ["gibibits"], unit: UnitInformationStorage.gibibits),
  MeasureInfo(names: ["tebibits"], unit: UnitInformationStorage.tebibits),
  MeasureInfo(names: ["pebibits"], unit: UnitInformationStorage.pebibits),
  MeasureInfo(names: ["exbibits"], unit: UnitInformationStorage.exbibits),
  MeasureInfo(names: ["zebibits"], unit: UnitInformationStorage.zebibits),
  MeasureInfo(names: ["yobibits"], unit: UnitInformationStorage.yobibits),

  MeasureInfo(names: ["kilobytes"], unit: UnitInformationStorage.kilobytes),
  MeasureInfo(names: ["megabytes"], unit: UnitInformationStorage.megabytes),
  MeasureInfo(names: ["gigabytes"], unit: UnitInformationStorage.gigabytes),
  MeasureInfo(names: ["terabytes"], unit: UnitInformationStorage.terabytes),
  MeasureInfo(names: ["petabytes"], unit: UnitInformationStorage.petabytes),
  MeasureInfo(names: ["exabytes"], unit: UnitInformationStorage.exabytes),
  MeasureInfo(names: ["zettabytes"], unit: UnitInformationStorage.zettabytes),
  MeasureInfo(names: ["yottabytes"], unit: UnitInformationStorage.yottabytes),

  MeasureInfo(names: ["kibibytes"], unit: UnitInformationStorage.kibibytes),
  MeasureInfo(names: ["mebibytes"], unit: UnitInformationStorage.mebibytes),
  MeasureInfo(names: ["gibibytes"], unit: UnitInformationStorage.gibibytes),
  MeasureInfo(names: ["tebibytes"], unit: UnitInformationStorage.tebibytes),
  MeasureInfo(names: ["pebibytes"], unit: UnitInformationStorage.pebibytes),
  MeasureInfo(names: ["exbibytes"], unit: UnitInformationStorage.exbibytes),
  MeasureInfo(names: ["zebibytes"], unit: UnitInformationStorage.zebibytes),
  MeasureInfo(names: ["yobibytes"], unit: UnitInformationStorage.yobibytes),

  // Length
  MeasureInfo(names: ["megameters"], unit: UnitLength.megameters),
  MeasureInfo(names: ["kilometers"], unit: UnitLength.kilometers),
  MeasureInfo(names: ["hectometers"], unit: UnitLength.hectometers),
  MeasureInfo(names: ["decameters"], unit: UnitLength.decameters),
  MeasureInfo(names: ["meters"], unit: UnitLength.meters),
  MeasureInfo(names: ["decimeters"], unit: UnitLength.decimeters),
  MeasureInfo(names: ["centimeters"], unit: UnitLength.centimeters),
  MeasureInfo(names: ["millimeters"], unit: UnitLength.millimeters),
  MeasureInfo(names: ["micrometers"], unit: UnitLength.micrometers),
  MeasureInfo(names: ["nanometers"], unit: UnitLength.nanometers),
  MeasureInfo(names: ["picometers"], unit: UnitLength.picometers),
  MeasureInfo(names: ["inches"], unit: UnitLength.inches),
  MeasureInfo(names: ["feet"], unit: UnitLength.feet),
  MeasureInfo(names: ["yards"], unit: UnitLength.yards),
  MeasureInfo(names: ["miles"], unit: UnitLength.miles),
  MeasureInfo(names: ["scandinavian miles"], unit: UnitLength.scandinavianMiles),
  MeasureInfo(names: ["light years"], unit: UnitLength.lightyears),
  MeasureInfo(names: ["nautical miles"], unit: UnitLength.nauticalMiles),
  MeasureInfo(names: ["fathoms"], unit: UnitLength.fathoms),
  MeasureInfo(names: ["furlongs"], unit: UnitLength.furlongs),
  MeasureInfo(names: ["astronomical units"], unit: UnitLength.astronomicalUnits),
  MeasureInfo(names: ["parsecs"], unit: UnitLength.parsecs),

  // Mass
  MeasureInfo(names: ["kilograms"], unit: UnitMass.kilograms),
  MeasureInfo(names: ["grams"], unit: UnitMass.grams),
  MeasureInfo(names: ["decigrams"], unit: UnitMass.decigrams),
  MeasureInfo(names: ["centigrams"], unit: UnitMass.centigrams),
  MeasureInfo(names: ["milligrams"], unit: UnitMass.milligrams),
  MeasureInfo(names: ["micrograms"], unit: UnitMass.micrograms),
  MeasureInfo(names: ["nanograms"], unit: UnitMass.nanograms),
  MeasureInfo(names: ["picograms"], unit: UnitMass.picograms),
  MeasureInfo(names: ["ounces"], unit: UnitMass.ounces),
  MeasureInfo(names: ["pounds"], unit: UnitMass.pounds),
  MeasureInfo(names: ["stones"], unit: UnitMass.stones),
  MeasureInfo(names: ["metric tons"], unit: UnitMass.metricTons),
  MeasureInfo(names: ["short tons"], unit: UnitMass.shortTons),
  MeasureInfo(names: ["carats"], unit: UnitMass.carats),
  MeasureInfo(names: ["ounces troy"], unit: UnitMass.ouncesTroy),
  MeasureInfo(names: ["slugs"], unit: UnitMass.slugs),

  // Power
  MeasureInfo(names: ["terawatts"], unit: UnitPower.terawatts),
  MeasureInfo(names: ["gigawatts"], unit: UnitPower.gigawatts),
  MeasureInfo(names: ["megawatts"], unit: UnitPower.megawatts),
  MeasureInfo(names: ["kilowatts"], unit: UnitPower.kilowatts),
  MeasureInfo(names: ["watts"], unit: UnitPower.watts),
  MeasureInfo(names: ["milliwatts"], unit: UnitPower.milliwatts),
  MeasureInfo(names: ["microwatts"], unit: UnitPower.microwatts),
  MeasureInfo(names: ["nanowatts"], unit: UnitPower.nanowatts),
  MeasureInfo(names: ["picowatts"], unit: UnitPower.picowatts),
  MeasureInfo(names: ["femtowatts"], unit: UnitPower.femtowatts),
  MeasureInfo(names: ["horsepower"], unit: UnitPower.horsepower),

  // Pressure
  MeasureInfo(names: ["pascals"], unit: UnitPressure.newtonsPerMetersSquared),
  MeasureInfo(names: ["gigapascals"], unit: UnitPressure.gigapascals),
  MeasureInfo(names: ["megapascals"], unit: UnitPressure.megapascals),
  MeasureInfo(names: ["kilopascals"], unit: UnitPressure.kilopascals),
  MeasureInfo(names: ["hectopascals"], unit: UnitPressure.hectopascals),
  MeasureInfo(names: ["inches of mercury"], unit: UnitPressure.inchesOfMercury),
  MeasureInfo(names: ["bars"], unit: UnitPressure.bars),
  MeasureInfo(names: ["millibars"], unit: UnitPressure.millibars),
  MeasureInfo(names: ["millimiters of mercury"], unit: UnitPressure.millimetersOfMercury),
  MeasureInfo(names: ["standard atmospheres", "atmospheres"], unit: UnitPressure.standardAtmospheres),
  MeasureInfo(names: ["pound per square inch"], unit: UnitPressure.poundsForcePerSquareInch),

  // Speed
  MeasureInfo(names: ["meters per second"], unit: UnitSpeed.metersPerSecond),
  MeasureInfo(names: ["kilometers per hour"], unit: UnitSpeed.kilometersPerHour),
  MeasureInfo(names: ["miles per hour"], unit: UnitSpeed.milesPerHour),
  MeasureInfo(names: ["knots"], unit: UnitSpeed.knots),

  // Temperature
  MeasureInfo(names: ["kelvin", "k"], unit: UnitTemperature.kelvin),
  MeasureInfo(names: ["degrees celsius", "celsius", "centigrade", "c"], unit: UnitTemperature.celsius),
  MeasureInfo(names: ["degrees fahrenheit", "fahrenheit", "f"], unit: UnitTemperature.fahrenheit),

  // Volume
  MeasureInfo(names: ["megaliters"], unit: UnitVolume.megaliters),
  MeasureInfo(names: ["kiloliters"], unit: UnitVolume.kiloliters),
  MeasureInfo(names: ["liters"], unit: UnitVolume.liters),
  MeasureInfo(names: ["deciliters"], unit: UnitVolume.deciliters),
  MeasureInfo(names: ["centiliters"], unit: UnitVolume.centiliters),
  MeasureInfo(names: ["milliliters"], unit: UnitVolume.milliliters),
  MeasureInfo(names: ["cubic kilometers"], unit: UnitVolume.cubicKilometers),
  MeasureInfo(names: ["cubic meters"], unit: UnitVolume.cubicMeters),
  MeasureInfo(names: ["cubic decimeters"], unit: UnitVolume.cubicDecimeters),
  MeasureInfo(names: ["cubic centimeters"], unit: UnitVolume.cubicCentimeters),
  MeasureInfo(names: ["cubic millimeters"], unit: UnitVolume.cubicMillimeters),
  MeasureInfo(names: ["cubic inches"], unit: UnitVolume.cubicInches),
  MeasureInfo(names: ["cubic feet"], unit: UnitVolume.cubicFeet),
  MeasureInfo(names: ["cubic yards"], unit: UnitVolume.cubicYards),
  MeasureInfo(names: ["cubic miles"], unit: UnitVolume.cubicMiles),
  MeasureInfo(names: ["acre feet"], unit: UnitVolume.acreFeet),
  MeasureInfo(names: ["bushels"], unit: UnitVolume.bushels),
  MeasureInfo(names: ["teaspoons"], unit: UnitVolume.teaspoons),
  MeasureInfo(names: ["tablespoons"], unit: UnitVolume.tablespoons),
  MeasureInfo(names: ["fluid ounces"], unit: UnitVolume.fluidOunces),
  MeasureInfo(names: ["cups"], unit: UnitVolume.cups),
  MeasureInfo(names: ["pints"], unit: UnitVolume.pints),
  MeasureInfo(names: ["quarts"], unit: UnitVolume.quarts),
  MeasureInfo(names: ["gallons"], unit: UnitVolume.gallons),
  MeasureInfo(names: ["imperial teaspoons"], unit: UnitVolume.imperialTeaspoons, imperial: true),
  MeasureInfo(names: ["imperial tablespoons"], unit: UnitVolume.imperialTablespoons, imperial: true),
  MeasureInfo(names: ["imperial fluid ounces"], unit: UnitVolume.imperialFluidOunces, imperial: true),
  MeasureInfo(names: ["imperial pints"], unit: UnitVolume.imperialPints, imperial: true),
  MeasureInfo(names: ["imperial quarts"], unit: UnitVolume.imperialQuarts, imperial: true),
  MeasureInfo(names: ["imperial gallons"], unit: UnitVolume.imperialGallons, imperial: true),
  MeasureInfo(names: ["metric cups"], unit: UnitVolume.metricCups)
]

// Parse input
let rawInput = CommandLine.arguments[1].trimmingCharacters(in: .whitespacesAndNewlines)

// Parse number value
guard
  let rawNumber = rawInput.firstMatch(of: #/^(\d+(\.\d+)?)\D*/#)?.1,
  let startNumber = Double(rawNumber)
else {
  showItems([
    ScriptFilterItem(
      uid: "Invalid Input",
      title: "Input a Value and Unit",
      subtitle: "Example: 42 km",
      autocomplete: nil,
      arg: nil,
      valid: false
    )
  ])

  exit(EXIT_FAILURE)
}

// Parse input minus number for starting measures
let rawOperation = rawInput.dropFirst(rawNumber.count).trimmingCharacters(in: .whitespacesAndNewlines)
let startMeasures = matchMeasures(from: rawOperation, in: allMeasures)

// When no starting measures specified, show them all
guard rawOperation.count > 0 else {
  let sfItems: [ScriptFilterItem] = allMeasures.map {
    let measure = $0
    let formatted = FormatMeasure(value: startNumber, measure: measure).string

    return ScriptFilterItem(
      uid: measure.symbol,
      title: formatted,
      subtitle: measure.names[0].capitalized,
      autocomplete: "\(formatted) to ",
      arg: nil,
      valid: false
    )
  }

  showItems(sfItems)
  exit(EXIT_SUCCESS)
}

// When no starting measures match, ask for corrections
guard startMeasures.count > 0 else {
  showItems([
    ScriptFilterItem(
      uid: "Invalid Unit",
      title: "Input a Valid Unit",
      subtitle: "Examples: km, kilometers",
      autocomplete: nil,
      arg: nil,
      valid: false
    )
  ])

  exit(EXIT_FAILURE)
}

// When multiple starting measures match, narrow with autocomplete
guard startMeasures.count < 2 else {
  let sfItems: [ScriptFilterItem] = startMeasures.map {
    let measure = $0.measure
    let formatted = FormatMeasure(value: startNumber, measure: measure).string

    return ScriptFilterItem(
      uid: measure.symbol,
      title: formatted,
      subtitle: measure.names[0].capitalized,
      autocomplete: "\(formatted) to ",
      arg: nil,
      valid: false
    )
  }

  showItems(sfItems)
  exit(EXIT_SUCCESS)
}

// Parse input minus number for starting measures and starting unit
let exactStartMeasure = startMeasures[0].measure
let rawEnd = rawOperation
  .dropFirst(startMeasures[0].matchedChars)
  .trimmingCharacters(in: .whitespacesAndNewlines)
  .removingPrefixes(["to ", "as ", "in "])  // Remove connection words

// When only one starting measure matches, convert
let endMeasures = {
  // Measures which make sense to convert to
  let suitableEnds = allMeasures.filter {
    type(of: exactStartMeasure.unit).baseUnit() == type(of: $0.unit).baseUnit()  // Same unit type, so we can convert
      && exactStartMeasure.unit != $0.unit  // Remove starting measure
  }

  // Filter further to targets that match, if any
  let desiredEnds = matchMeasures(from: rawEnd, in: suitableEnds).map { $0.measure }

  // Return all targets if none match, otherwise return matching targets
  return desiredEnds.count == 0 ? suitableEnds : desiredEnds
}()

// Parse and convert
let startDimension = Measurement(value: startNumber, unit: exactStartMeasure.unit)
let formattedStartDimension = FormatMeasure(value: startDimension.value, measure: exactStartMeasure).string

let sfItems: [ScriptFilterItem] = endMeasures.map {
  let measure = $0
  let converted = startDimension.converted(to: measure.unit)
  let formatted = FormatMeasure(value: converted.value, measure: measure).string

  return ScriptFilterItem(
    uid: "\(exactStartMeasure.symbol) to \($0.unit.symbol)",
    title: formatted,
    subtitle: "\(exactStartMeasure.names[0].capitalized) → \($0.names[0].capitalized)",
    autocomplete: "\(formattedStartDimension) to \($0.symbol)",
    arg: formatted,
    valid: true
  )
}

showItems(sfItems)
