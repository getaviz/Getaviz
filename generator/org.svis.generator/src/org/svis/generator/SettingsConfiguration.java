package org.svis.generator;

import java.io.File;
import java.awt.Color;

import org.apache.commons.configuration2.PropertiesConfiguration;
import org.apache.commons.configuration2.builder.fluent.Configurations;
import org.apache.commons.configuration2.ex.ConfigurationException;
import org.svis.generator.city.CitySettings.Bricks.Layout;
import org.svis.generator.city.CitySettings.BuildingType;
import org.svis.generator.city.CitySettings.ClassElementsModes;
import org.svis.generator.city.CitySettings.ClassElementsSortModesCoarse;
import org.svis.generator.city.CitySettings.ClassElementsSortModesFine;
import org.svis.generator.city.CitySettings.Original.BuildingMetric;
import org.svis.generator.city.CitySettings.Panels.SeparatorModes;
import org.svis.generator.city.CitySettings.Schemes;
import org.svis.generator.famix.FAMIXSettings.FamixParser;
import org.svis.generator.rd.RDSettings.EvolutionRepresentation;
import org.svis.generator.rd.RDSettings.InvocationRepresentation;
import org.svis.generator.rd.RDSettings.MetricRepresentation;
import org.svis.generator.rd.RDSettings.Variant;

public class SettingsConfiguration {
	private static PropertiesConfiguration config;
	private static SettingsConfiguration instance = null;

	private SettingsConfiguration() {
	}

	public static SettingsConfiguration getInstance() {
		if (instance == null) {
			instance = new SettingsConfiguration();
			loadConfig("../org.svis.generator.releng/settings.properties");
		}
		return instance;
	}

	public static SettingsConfiguration getInstance(String path) {
		if (instance == null) {
			instance = new SettingsConfiguration();
		}
		loadConfig(path);
		return instance;
	}

	private static void loadConfig(String path) {
		File file = new File(path);
		try {
			Configurations configs = new Configurations();
			config = configs.properties(file);
		} catch (ConfigurationException cex) {
			System.out.println(cex);
		}
	}

	public void loadDefault() {
		loadConfig("../org.svis.generator.releng/settings.properties");
	}

	public String getRepositoryName() {
		return config.getString("history.repository_name", "");
	}

	public String getRepositoryOwner() {
		return config.getString("history.repository_owner", "");
	}

	public String getDatabaseName() {
		return config.getString("database_name", "../databases/graph.db");
	}

	public OutputFormat getOutputFormat() {
		switch (config.getString("output_format", "x3d")) {
		case "x3dom":
			return OutputFormat.X3DOM;
		case "aframe":
			return OutputFormat.AFrame;
		case "simple_glyphs_json":
			return OutputFormat.SimpleGlyphsJson;
		case "x3d_compressed":
			return OutputFormat.X3D_COMPRESSED;
		default:
			return OutputFormat.X3D;
		}
	}

	public boolean isHidePrivateElements() {
		return config.getBoolean("structure.hide_private_elements", false);
	}

	public String getParserAsString() {
		return config.getString("structure.parser", "verveinej");
	}
	
	public FamixParser getParser() {
		switch (getParserAsString()) {
		case "jdt2famix":
			return FamixParser.JDT2FAMIX;
		case "jqa_bytecode":
			return FamixParser.JQA_BYTECODE;
		default:
			return FamixParser.VERVEINEJ;
		}
	}

	public boolean isAttributeSortSize() {
		return config.getBoolean("structure.attribute_sort_size", false);
	}

	public boolean isMasterRoot() {
		return config.getBoolean("structure.master_root", false);
	}

	public boolean isMergePackages() {
		return config.getBoolean("structure.merge_packages", false);
	}

	public String getBuildingTypeAsString() {
		return config.getString("city.building_type", "original");
	}

	public BuildingType getBuildingType() {
		switch (getBuildingTypeAsString()) {
		case "panels":
			return BuildingType.CITY_PANELS;
		case "bricks":
			return BuildingType.CITY_BRICKS;
		case "floor":
			return BuildingType.CITY_FLOOR;
		case "dynamic":
			return BuildingType.CITY_DYNAMIC;
		default:
			return BuildingType.CITY_ORIGINAL;
		}
	}

	public String getSchemeAsString() {
		return config.getString("city.scheme", "types");
	}

	public Schemes getScheme() {
		switch (getSchemeAsString()) {
		case "visibility":
			return Schemes.VISIBILITY;
		default:
			return Schemes.TYPES;
		}
	}

	public String getClassElementsModeAsString() {
		return config.getString("city.class_elements_mode", "methods_and_attributes");
	}

	public ClassElementsModes getClassElementsMode() {
		switch (getClassElementsModeAsString()) {
		case "methods_only":
			return ClassElementsModes.METHODS_ONLY;
		case "attributes_only":
			return ClassElementsModes.ATTRIBUTES_ONLY;
		default:
			return ClassElementsModes.METHODS_AND_ATTRIBUTES;
		}
	}

	public String getClassElementsSortModeCoarseAsString() {
		return config.getString("city.class_elements_sort_mode_coarse", "methods_first");
	}

	public ClassElementsSortModesCoarse getClassElementsSortModeCoarse() {
		switch (getClassElementsSortModeCoarseAsString()) {
		case "unsorted":
			return ClassElementsSortModesCoarse.UNSORTED;
		case "attributes_first":
			return ClassElementsSortModesCoarse.ATTRIBUTES_FIRST;
		default:
			return ClassElementsSortModesCoarse.METHODS_FIRST;
		}
	}

	public String getClassElementsSortModeFineAsString() {
		return config.getString("city.elements_sort_mode_fine", "scheme");
	}

	public ClassElementsSortModesFine getClassElementsSortModeFine() {
		switch (getClassElementsSortModeFineAsString()) {
		case "unsorted":
			return ClassElementsSortModesFine.UNSORTED;
		case "alphabetically":
			return ClassElementsSortModesFine.ALPHABETICALLY;
		case "nos":
			return ClassElementsSortModesFine.NOS;
		default:
			return ClassElementsSortModesFine.SCHEME;
		}
	}

	public boolean isClassElementsSortModeFineDirectionReversed() {
		return config.getBoolean("city.class_elements_sort_mode_fine_direction_reversed", false);
	}

	public boolean isShowBuildingBase() {
		return config.getBoolean("city.building_base", true);
	}

	public String getBrickLayoutAsString() {
		return config.getString("city.brick.layout", "progressive");
	}

	public Layout getBrickLayout() {
		switch (getBrickLayoutAsString()) {
		case "straight":
			return Layout.STRAIGHT;
		case "balanced":
			return Layout.BALANCED;
		default:
			return Layout.PROGRESSIVE;
		}
	}

	public double getBrickSize() {
		return config.getDouble("city.brick.size", 1.0);
	}

	public double getBrickHorizontalMargin() {
		return config.getDouble("city.brick.horizontal_margin", 0.5);
	}

	public double getBrickHorizontalGap() {
		return config.getDouble("city.brick.horizontal_gap", 0.2);
	}

	public double getBrickVerticalMargin() {
		return config.getDouble("city.brick.vertical_margin", 0.2);
	}

	public double getBrickVerticalGap() {
		return config.getDouble("city.brick.vertical_gap", 0.2);
	}

	public boolean isShowAttributesAsCylinders() {
		return config.getBoolean("city.show_attributes_as_cylinders", true);
	}

	public String getPanelSeparatorModeAsString() {
		return config.getString("city.panel_separator_mode", "separator");
	}

	public SeparatorModes getPanelSeparatorMode() {
		switch (getPanelSeparatorModeAsString()) {
		case "none":
			return SeparatorModes.NONE;
		case "gap":
			return SeparatorModes.GAP;
		default:
			return SeparatorModes.SEPARATOR;
		}
	}

	public int[] getPanelHeightTresholdNos() {
		int[] defaultValue = { 3, 6, 12, 24, 48, 96, 144, 192, 240 };
		String[] result = config.getStringArray("city.panel.height_treshold_nos");
		if (result.length == 0) {
			return defaultValue;
		} else {
			int[] value = new int[result.length];
			for (int i = 0; i < result.length; i++) {
				value[i] = Integer.parseInt(result[i]);
				System.out.print(value[i] +  " ");
			}
			return value;
		}
	}

	public double getPanelHeightUnit() {
		return config.getDouble("city.panel.height_unit", 0.5);
	}

	public double getPanelHorizontalMargin() {
		return config.getDouble("city.panel.horizontal_margin", 0.5);
	}

	public double getPanelVerticalMargin() {
		return config.getDouble("city.panel.vertical_margin", 0.25);
	}

	public double getPanelVerticalGap() {
		return config.getDouble("city.panel.vertical_gap", 0.125);
	}

	public double getPanelSeparatorHeight() {
		return config.getDouble("city.panel.separator_height", 0.125);
	}

	public String getOriginalBuildingMetricAsString() {
		return config.getString("city.original_building_metric", "none");
	}

	public BuildingMetric getOriginalBuildingMetric() {
		switch (getOriginalBuildingMetricAsString()) {
		case "nos":
			return BuildingMetric.NOS;
		default:
			return BuildingMetric.NONE;
		}
	}

	public double getWidthMin() {
		return config.getDouble("city.width_min", 1.0);
	}

	public double getHeightMin() {
		return config.getDouble("city.height_min", 1.0);
	}

	public double getBuildingHorizontalMargin() {
		return config.getDouble("city.building.horizontal_margin", 3.0);
	}

	public double getBuildingHorizontalGap() {
		return config.getDouble("city.building.horizontal_gap", 3.0);
	}

	public double getBuildingVerticalMargin() {
		return config.getDouble("city.building.vertical_margin", 1.0);
	}

	public String getPackageColorHex() {
		return config.getString("city.package.color_start", "#969696");
	}

	public Color getPackageColorStart() {
		return getColor(config.getString("city.package.color_start", "#969696"));
	}

	public Color getPackageColorEnd() {
		return getColor(config.getString("city.package.color_end", "#f0f0f0"));
	}

	public String getClassColorHex() {
		return config.getString("city.class.color", "#353559");
	}

	public Color getClassColorStart() {
		return getColor(config.getString("city.class.color_start", "#131615"));
	}

	public Color getClassColorEnd() {
		return getColor(config.getString("city.class.color_end", "#00ff00"));
	}

	public Color getClassColor() {
		return getColor(config.getString("city.class.color", "#353559"));
	}

	public Color getDynamicClassColorStart() {
		return getColor(config.getString("city.dynamic.class.color_start", "#fa965c"));
	}

	public Color getDynamicClassColorEnd() {
		return getColor(config.getString("city.dynamic.class.color_end", "#feb280"));
	}

	public Color getDynamicMethodColor() {
		return getColor(config.getString("city.dynamic.method.color", "#735eb9"));
	}

	public Color getDynamicPackageColorStart() {
		return getColor(config.getString("city.dynamic.package.color_start", "#23862c"));
	}

	public Color getDynamicPackageColorEnd() {
		return getColor(config.getString("city.dynamic.package.color_end", "#7bcd8d"));
	}

	public Color getCityColor(String name) {
		return getColor(getCityColorHex(name));
	}

	public String getCityColorHex(String name) {
		String color = name.toLowerCase();
		String defaultColor = "";
		switch (name) {
		case "aqua":
			defaultColor = "#99CCFF"; break;
		case "blue":
			defaultColor = "#99FFCC"; break;
		case "light_green":
			defaultColor = "#CCFF99"; break;
		case "dark_green":
			defaultColor = "#99FF99"; break;
		case "yellow":
			defaultColor = "#FFFF99"; break;
		case "orange":
			defaultColor = "#FFCC99"; break;
		case "red":
			defaultColor = "#FF9999"; break;
		case "pink":
			defaultColor = "#FF99FF"; break;
		case "violet":
			defaultColor = "#9999FF"; break;
		case "light_grey":
			defaultColor = "#CCCCCC"; break;
		case "dark_grey":
			defaultColor = "#999999"; break;
		case "white":
			defaultColor = "#FFFFFF"; break;
		case "black":
			defaultColor = "#000000"; break;
		}
		return config.getString("city.color." + color, defaultColor);
	}

	public String getCityColorAsPercentage(String name) {
		return getColorFormatted(getCityColor(name));
	}

	public double getRDDataFactor() {
		return config.getDouble("rd.data_factor", 4.0);
	}

	public double getRDMethodFactor() {
		return config.getDouble("rd.method_factor", 1.0);
	}

	public double getRDHeight() {
		return config.getDouble("rd.height", 1.0);
	}

	public int getRDHeightBoost() {
		return config.getInt("rd.height_boost", 8);
	}

	public float getRDHeightMultiplicator() {
		return (float)config.getDouble("rd.height_multiplicator", 50.0);
	}

	public double getRDRingWidth() {
		return config.getDouble("rd.ring_width", 2.0);
	}

	public double getRDRingWidthMD() {
		return config.getDouble("rd.ring_width_md", 0);
	}

	public double getRDRingWidthAD() {
		return config.getDouble("rd.ring_width_ad", 0);
	}

	public double getRDMinArea() {
		return config.getDouble("rd.min_area", 10.0);
	}

	public double getRDNamespaceTransparency() {
		return config.getDouble("rd.namespace_transparency", 0);
	}

	public double getRDClassTransparency() {
		return config.getDouble("rd.class_transparency", 0);
	}

	public double getRDMethodTransparency() {
		return config.getDouble("rd.method_transparency", 0);
	}

	public double getRDDataTransparency() {
		return config.getDouble("rd.data_transparency", 0);
	}

	public Color getRDClassColor() {
		return getColor(getRDClassColorHex());
	}

	public String getRDClassColorHex() {
		return config.getString("rd.color.class", "#353559");
	}

	public String getRDClassColorAsPercentage() {
		return getColorFormatted(getRDClassColor());
	}

	public Color getRDDataColor() {
		return getColor(getRDDataColorHex());
	}

	public String getRDDataColorHex() {
		return config.getString("rd.color.data", "#fffc19");
	}

	public String getRDDataColorAsPercentage() {
		return getColorFormatted(getRDDataColor());
	}

	public Color getRDMethodColor() {
		return getColor(getRDMethodColorHex());
	}

	public String getRDMethodColorHex() {
		return config.getString("rd.color.method", "#1485cc");
	}

	public String getRDMethodColorAsPercentage() {
		return getColorFormatted(getRDMethodColor());
	}

	public Color getRDNamespaceColor() {
		return getColor(getRDNamespaceColorHex());
	}

	public String getRDNamespaceColorHex() {
		return config.getString("rd.color.namespace", "#969696");
	}

	public String getRDNamespaceColorAsPercentage() {
		return getColorFormatted(getRDNamespaceColor());
	}

	public Color getRDMethodInvocationColor() {
		return getColor(config.getString("rd.color.method_invocation", "#780a32"));
	}

	public String getRDMethodInvocationColorAsPercentage() {
		return getColorFormatted(getRDMethodInvocationColor());
	}

	public boolean isMethodDisks() {
		return config.getBoolean("rd.method_disks", false);
	}

	public boolean isDataDisks() {
		return config.getBoolean("rd.data_disks", false);
	}

	public boolean isMethodTypeMode() {
		return config.getBoolean("rd.method_type_mode", false);
	}

	public String getMetricRepresentationAsString() {
		return config.getString("rd.metric_representation", "none");
	}

	public MetricRepresentation getMetricRepresentation() {
		switch (getMetricRepresentationAsString()) {
		case "height":
			return MetricRepresentation.HEIGHT;
		case "luminance":
			return MetricRepresentation.LUMINANCE;
		case "frequency":
			return MetricRepresentation.FREQUENCY;
		default:
			return MetricRepresentation.NONE;
		}
	}

	public String getInvocationRepresentationAsString() {
		return config.getString("rd.invocation_representation", "none");
	}

	public InvocationRepresentation getInvocationRepresentation() {
		switch (getInvocationRepresentationAsString()) {
		case "moving_spheres":
			return InvocationRepresentation.MOVING_SPHERES;
		case "flashing_methods":
			return InvocationRepresentation.FLASHING_METHODS;
		case "moving_flashing":
			return InvocationRepresentation.MOVING_FLASHING;
		default:
			return InvocationRepresentation.NONE;
		}
	}

	public String getEvolutionRepresentationAsString() {
		return config.getString("rd.evolution_representation", "time_line");
	}

	public EvolutionRepresentation getEvolutionRepresentation() {
		switch (getEvolutionRepresentationAsString()) {
		case "dynamic_evolution":
			return EvolutionRepresentation.DYNAMIC_EVOLUTION;
		case "multiple_time_line":
			return EvolutionRepresentation.MULTIPLE_TIME_LINE;
		case "multiple_dynamic_evolution":
			return EvolutionRepresentation.MULTIPLE_DYNAMIC_EVOLUTION;
		default:
			return EvolutionRepresentation.TIME_LINE;
		}
	}

	public String getVariantAsString() {
		return config.getString("rd.variant", "static");
	}

	public Variant getVariant() {
		switch (getVariantAsString()) {
		case "dynamic":
			return Variant.DYNAMIC;
		default:
			return Variant.STATIC;
		}
	}

	public String getPackageShape() {
		String value = config.getString("plant.package.shape", "default");
		return value.toUpperCase();
	}

	public boolean isPackageUseTextures() {
		return config.getBoolean("plant.package.use_textures", true);
	}

	public String getPackageOddTexture() {
		return config.getString("plant.package.odd_texture", "<ImageTexture url='pics/ground.png' scale='false' />");
	}

	public String getPackageEvenTexture() {
		return config.getString("plant.package.even_texture", "<ImageTexture url='pics/freeGrass.png' scale='false' />");
	}

	public String getPackageOddColor() {
		Color color = getColor(config.getString("plant.package.odd_color", "#964327"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getPackageEvenColor() {
		Color color = getColor(config.getString("plant.package.even_color", "#30ba43"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String switchAttributeMethodMapping() {
		String value = config.getString("plant.switch_attribute_method_mapping", "petal_pollstem");
		return value.toUpperCase();
	}

	public String getClassShape() {
		String value = config.getString("plant.class.shape", "default");
		return value.toUpperCase();
	}

	public boolean isClassUseTextures() {
		return config.getBoolean("plant.class.use_textures", false);
	}

	public String getClassSize() {
		return config.getString("plant.class.size", "count_attributes_and_methods");
	}

	public String getClassTexture() {
		return config.getString("plant.class.texture", "<ImageTexture url='pics/plant.png' scale='true' />");
	}

	public String getClassTextureHeadBrown() {
		return config.getString("plant.class.texture_head_brown", "<ImageTexture url='pics/plant.png' scale='true' />");
	}

	public String getClassTextureBloom() {
		return config.getString("plant.class.texture_bloom", "<ImageTexture url='pics/bloom.png' scale='false' />");
	}

	public String getPlantClassColor() {
		Color color = getColor(config.getString("plant.class.color", "#34663b"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getPlantClassColor02() {
		Color color = getColor(config.getString("plant.class.color02", "#8b4413"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getPlantClassColor03() {
		Color color = getColor(config.getString("plant.class.color03", "#ffff00"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getInnerClassShape() {
		String value = config.getString("plant.inner_class.shape", "default");
		return value.toUpperCase();
	}

	public boolean isInnerClassUseTextures() {
		return config.getBoolean("plant.inner_class.use_textures", false);
	}

	public String getInnerClassTexture() {
		return config.getString("plant.inner_class.texture", "<ImageTexture url='pics/plant.png' scale='true' />");
	}

	public String getInnerClassTextureJunctionHeadTopPart() {
		return config.getString("plant.inner_class.texture_head_brown",
				"<ImageTexture url='pics/junctionHeadTopPart.png' scale='false' />");
	}

	public String getInnerClassTextureBloom() {
		return config.getString("plant.inner_class.texture_bloom",
				"<ImageTexture url='pics/bloom.png' scale='false' />");
	}

	public String getInnerClassColor() {
		Color color = getColor(config.getString("plant.inner_class.color", "#329c3c"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getInnerClassColor02() {
		Color color = getColor(config.getString("plant.inner_class.color02", "#8b4413"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getInnerClassColor03() {
		Color color = getColor(config.getString("plant.inner_class.color03", "#ffff00"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getAttributeShape() {
		String value = config.getString("plant.attribute.shape", "realistic_petal");
		return value.toUpperCase();
	}

	public boolean isShowAttributes() {
		return config.getBoolean("plant.attribute.show", true);
	}

	public Boolean isAttributeUseTextures() {
		return config.getBoolean("plant.attribute.use_textures", true);
	}

	public String getAttributeTexture() {
		return config.getString("plant.attribute.texture", "<ImageTexture url='pics/lilacPetal.png' scale='false' />");
	}

	public String getAttributeColor() {
		Color color = getColor(config.getString("plant.attribute.color", "#8a3398"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getInnerClassAttributeShape() {
		String value = config.getString("plant.inner_class_attribute.shape", "default");
		return value.toUpperCase();
	}

	public String getInnerClassAttributeTexture() {
		return config.getString("plant.inner_class_attribute.texture",
				"<ImageTexture url='pics/lilacPetal.png' scale='false' />");
	}

	public String getInnerClassAttributeColor() {
		Color color = getColor(config.getString("plant.inner_class_attribute.color", "#ab2626"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getMethodShape() {
		String value = config.getString("plant.method.shape", "default");
		return value.toUpperCase();
	}

	public boolean isShowMethods() {
		return config.getBoolean("plant.method.show", true);
	}

	public Boolean isMethodUseTextures() {
		return config.getBoolean("plant.method.use_textures", true);
	}

	public String getMethodTexture() {
		return config.getString("plant.method.texture", "<ImageTexture url='pics/junctionGreen.png' scale='false' />");
	}

	public String getMethodTexturePollball() {
		return config.getString("plant.method.texture_pollball",
				"<ImageTexture url='pics/pollball.png' scale='false' />");
	}

	public String getMethodColor() {
		Color color = getColor(config.getString("plant.method.color", "#00FF00"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getMethodColor02() {
		Color color = getColor(config.getString("plant.method.color", "#FFFF00"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public String getInnerClassMethodShape() {
		String value = config.getString("plant.inner_class_method.shape", "default");
		return value.toUpperCase();
	}

	public String getInnerClassMethodTexture() {
		return config.getString("plant.inner_class_method.texture",
				"<ImageTexture url='pics/bloom.png' scale='false' />");
	}

	public String getInnerClassMethodColor() {
		Color color = getColor(config.getString("plant.inner_class_method.color", "#8b4413"));
		return getPlantColorFormatted(getColorFormatted(color));
	}

	public double getAreaHeight() {
		return config.getDouble("plant.area_height", 3.5);
	}

	public double getStemThickness() {
		return config.getDouble("plant.stem.thickness", 3.0);
	}

	public double getStemHeight() {
		return config.getDouble("plant.stem.height", 6.0);
	}

	public double getCronHeight() {
		return config.getDouble("plant.cron.height", 2.0);
	}

	public double getCronHeadHeight() {
		return config.getDouble("plant.cron.head_height", 0.5);
	}

	public double getPetalAngle() {
		return config.getDouble("plant.petal.angle", 0.5236);
	}

	public double getPetalDistanceMultiplier() {
		return config.getDouble("plant.petal.distance_multiplier", 3.0);
	}

	public double getPollstemAngle() {
		return config.getDouble("plant.pollstem.angle", 0.05);
	}

	public double getPollstemAngleDistanceMultiplier() {
		return config.getDouble("plant.pollstem.angle_distance_multiplier", 0.3);
	}

	public double getPollstemBallMultiplier() {
		return config.getDouble("plant.pollstem.ball_multiplier", 1.57);
	}

	public double getPollstemBallHeight() {
		return getCronHeight() + 3.87;
	}

	public double getJunctionAngle() {
		return config.getDouble("plant.junction.angle", 1.3);
	}

	public double getJunctionStemThickness() {
		return getStemThickness() / 2;
	}

	public double getJunctionDistanceMultiplier() {
		return config.getDouble("plant.junction.distance_multiplier", 8.0);
	}

	public double getJunctionPollstemBallMultiplier() {
		return config.getDouble("plant.junction.pollstem.ball_multiplier", 0.1);
	}

	public double getPlantBuildingHorizontalMargin() {
		return config.getDouble("plant.building.horizontal_margin", 3.0);
	}

	public double getPlantBuildingHorizontalGap() {
		return config.getDouble("plant.building.horizontal_gap", 7.0);
	}

	public double getPlantBuildingVerticalMargin() {
		return config.getDouble("plant.building.vertical_margin", 1.0);
	}

	private String getColorFormatted(Color color) {
		//double[] rgb = color.getColorComponents(null);
		double r = color.getRed() / 255.0;
		double g = color.getGreen() / 255.0;
		double b = color.getBlue() / 255.0;
		return r + " " + g + " " + b;
	}

	private String getPlantColorFormatted(String formattedColor) {
		return "<Material diffuseColor='" + formattedColor + "' />";
	}

	private Color getColor(String hex) {
		return Color.decode(hex);
	}

	public static enum OutputFormat {
		X3D, X3DOM, SimpleGlyphsJson, X3D_COMPRESSED, AFrame;
	}
}