package org.svis.generator.city.s2m

import java.util.List
import java.util.Set
import org.eclipse.emf.mwe.core.WorkflowContext
import org.eclipse.emf.mwe.core.issues.Issues
import org.eclipse.emf.mwe.core.monitor.ProgressMonitor
import org.svis.generator.FamixUtils
import org.svis.generator.city.CityUtils
import org.svis.xtext.city.Building
import org.svis.xtext.city.BuildingSegment
import org.svis.xtext.city.District
import org.svis.xtext.city.Root
import org.svis.xtext.city.impl.CityFactoryImpl
import org.svis.xtext.famix.Document
import org.svis.xtext.famix.FAMIXAttribute
import org.svis.xtext.famix.FAMIXEnum
import org.svis.xtext.famix.FAMIXEnumValue
import org.svis.xtext.famix.FAMIXFileAnchor
import org.svis.xtext.famix.FAMIXInheritance
import org.svis.xtext.famix.FAMIXLocalVariable
import org.svis.xtext.famix.FAMIXClass
import org.svis.xtext.famix.FAMIXMethod
import org.svis.xtext.famix.FAMIXNamespace
import org.svis.xtext.famix.FAMIXParameter
import org.svis.xtext.famix.FAMIXParameterizedType
import org.svis.xtext.famix.FAMIXPrimitiveType
import org.svis.xtext.famix.FAMIXReference
import org.svis.xtext.famix.FAMIXStructure
import org.svis.generator.SettingsConfiguration
import org.eclipse.emf.mwe.core.lib.WorkflowComponentWithModelSlot
import org.apache.commons.logging.LogFactory
import org.svis.generator.SettingsConfiguration.BuildingType
import org.svis.generator.SettingsConfiguration.ClassElementsModes
import org.svis.generator.SettingsConfiguration.Original.BuildingMetric
import org.svis.generator.SettingsConfiguration.FamixParser
import static org.apache.commons.codec.digest.DigestUtils.sha1Hex
import org.svis.generator.SettingsConfiguration.AbapCityRepresentation

// ABAP
import org.svis.xtext.famix.FAMIXReport 
import org.svis.xtext.famix.FAMIXDictionaryData
import org.svis.xtext.famix.FAMIXDataElement
import org.svis.xtext.famix.FAMIXDomain
import org.svis.xtext.famix.FAMIXTable
import org.svis.xtext.famix.FAMIXABAPStruc
import org.svis.xtext.famix.FAMIXStrucElement
import org.svis.xtext.famix.FAMIXFunctionGroup
import org.svis.xtext.famix.FAMIXFunctionModule
import org.svis.xtext.famix.FAMIXFormroutine
import org.svis.xtext.famix.FAMIXMessageClass 
import org.svis.xtext.famix.FAMIXTableType 
import org.svis.xtext.famix.FAMIXTypeOf
import org.svis.xtext.famix.FAMIXTableElement



class Famix2City_abap {
	//Import: cityDocument, to store all elements from famixDocument
	new(org.svis.xtext.city.Document imp_cityDocument, Document imp_famixDocument){
		cityDocument  = imp_cityDocument
		famixDocument = imp_famixDocument
		
		rootPackages 		+= famixDocument.elements.filter(FAMIXNamespace).filter[parentScope === null]
		subPackages 		+= famixDocument.elements.filter(FAMIXNamespace).filter[parentScope !== null]
		structures 			+= famixDocument.elements.filter(FAMIXStructure)
 		classes 			+= famixDocument.elements.filter(FAMIXClass)
		methods 			+= famixDocument.elements.filter(FAMIXMethod)
		localVariables 		+= famixDocument.elements.filter(FAMIXLocalVariable)
		attributes 			+= famixDocument.elements.filter(FAMIXAttribute)
		enums 			    += famixDocument.elements.filter(FAMIXEnum)
		enumValues			+= famixDocument.elements.filter(FAMIXEnumValue)
		primitiveTypes 		+= famixDocument.elements.filter(FAMIXPrimitiveType)
		parameterizedTypes  += famixDocument.elements.filter(FAMIXParameterizedType)
		inheritances 		+= famixDocument.elements.filter(FAMIXInheritance)
		references 			+= famixDocument.elements.filter(FAMIXReference)
		parameters 			+= famixDocument.elements.filter(FAMIXParameter)
		
		//ABAP
		reports 	 	 += famixDocument.elements.filter(FAMIXReport)
		formroutines	 += famixDocument.elements.filter(FAMIXFormroutine)
		dataElements	 += famixDocument.elements.filter(FAMIXDataElement)
		domains			 += famixDocument.elements.filter(FAMIXDomain)
		tables			 += famixDocument.elements.filter(FAMIXTable)
		abapStrucs		 += famixDocument.elements.filter(FAMIXABAPStruc)
		abapStrucElem    += famixDocument.elements.filter(FAMIXStrucElement)
		functionGroups   += famixDocument.elements.filter(FAMIXFunctionGroup)
		functionModules  += famixDocument.elements.filter(FAMIXFunctionModule)
		messageClasses   += famixDocument.elements.filter(FAMIXMessageClass)
		tableTypes		 += famixDocument.elements.filter(FAMIXTableType)
		typeOf			 += famixDocument.elements.filter(FAMIXTypeOf)
		tableElements	 += famixDocument.elements.filter(FAMIXTableElement)
		
		dcData	 		 += dataElements + domains + abapStrucs + tableTypes 
		
		if(!config.showOwnTablesDistrict){
			dcData += tables
		}
	}
		
	val config = SettingsConfiguration.instance
	val log = LogFactory::getLog(class)
	val cityFactory = new CityFactoryImpl
	var Document famixDocument
	var org.svis.xtext.city.Document cityDocument
	
	extension FamixUtils util = new FamixUtils

	val Set<FAMIXNamespace> rootPackages = newLinkedHashSet
	val Set<FAMIXNamespace> subPackages = newLinkedHashSet
	val List<FAMIXStructure> structures = newArrayList
	val List<FAMIXClass> classes = newArrayList
	val List<FAMIXMethod> methods = newArrayList
	val List<FAMIXLocalVariable> localVariables = newArrayList
	val List<FAMIXAttribute> attributes = newArrayList
	val List<FAMIXEnum> enums = newArrayList
	val List<FAMIXEnumValue> enumValues = newArrayList
	val List<FAMIXPrimitiveType> primitiveTypes = newArrayList
	val List<FAMIXParameterizedType> parameterizedTypes = newArrayList
	var List<FAMIXInheritance> inheritances = newArrayList
	var List<FAMIXReference> references = newArrayList
	val List<FAMIXParameter> parameters = newArrayList
	
	var org.svis.xtext.city.District originDistrict = cityFactory.createDistrict
	
	//ABAP
	val List<FAMIXReport> reports = newArrayList 
	val List<FAMIXDictionaryData> dcData = newArrayList
	val List<FAMIXDataElement> dataElements = newArrayList 
	val List<FAMIXDomain> domains = newArrayList
	val List<FAMIXTable> tables = newArrayList 
	val List<FAMIXABAPStruc> abapStrucs = newArrayList 
	val List<FAMIXStrucElement> abapStrucElem = newArrayList 
	val List<FAMIXFunctionModule> functionModules = newArrayList
	val List<FAMIXFormroutine> formroutines = newArrayList
	val List<FAMIXMessageClass> messageClasses = newArrayList
	val List<FAMIXFunctionGroup> functionGroups = newArrayList
	val List<FAMIXTableType> tableTypes = newArrayList
	val List<FAMIXTypeOf> typeOf = newArrayList
	val List<FAMIXTableElement> tableElements = newArrayList
	
	
	def abapToModel(){		
		// Run transformation 
		if(config.abap_representation == AbapCityRepresentation::SIMPLE){
			simpleModel()
		}else if(config.abap_representation == AbapCityRepresentation::ADVANCED){
			advancedModel()
		}		
		
		return cityDocument
	}
	
	
	def void logElement(Object el){
		log.info(el)
	}
	
	
	/**
	 * Transform famix to City, SIMPLE representation
	 * 1. Group objects by type and art
	 * 2. Create district for groups
	 * 3. Use simple forms (city2X3D)
	 */
	def simpleModel(){
		rootPackages.forEach[toDistrict(1)]
	}
	
	
	/**
	 * Transform famix to City, ADVANCED representation
	 * 1. Build city using dependencies
	 * 2. Use more complex buildings (city2X3D)
	 */
	def advancedModel(){
		rootPackages.forEach[toAdvancedDistrict(1)]
	}
	
	
	// Mode: simple
	def private District toDistrict(FAMIXNamespace elem, int level) {	
		
		// Create main district		
		val newDistrict = cityFactory.createDistrict
		newDistrict.name = elem.name
		newDistrict.value = elem.value
		newDistrict.fqn = elem.fqn
		newDistrict.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newDistrict.level = level
		newDistrict.id = elem.id
		if(elem.iteration >= 1){
			newDistrict.notInOrigin = "true"
		}
		
		// Test mode -> Delete for dist		
		if(!config.abapCityTestMode){
			//Sub packages
			subPackages.filter[parentScope.ref === elem].forEach[newDistrict.entities += toDistrict(level + 1)]
			
			//Data Dictionary
			if (dcData.filter[container.ref == elem].length != 0){
				val dcDataDistrict = cityFactory.createDistrict
				dcDataDistrict.name = newDistrict.name + "_dcDataDistrict"
				dcDataDistrict.type = "dcDataDistrict"
				dcDataDistrict.id = elem.id + "_00002"
				dcDataDistrict.level = level + 1
				if(elem.iteration >= 1){
					dcDataDistrict.notInOrigin = "true"
				}
				
				dcData.filter[container.ref == elem].forEach[dcDataDistrict.entities += toBuilding(level + 2)]
				newDistrict.entities.add(dcDataDistrict)
			}
			
			//Reports (+forms)
			if (reports.filter[container.ref == elem].length != 0){
				val reportDistrict = cityFactory.createDistrict
				reportDistrict.name = newDistrict.name + "_reportDistrict"
				reportDistrict.type = "reportDistrict"
				reportDistrict.id = elem.id + "_00003"
				reportDistrict.level = level + 1
				if(elem.iteration >= 1){
					reportDistrict.notInOrigin = "true"
				}
				
				reports.filter[container.ref == elem].forEach[reportDistrict.entities += toBuilding(level + 2)]
				newDistrict.entities.add(reportDistrict)
			}
			
			//Classes (+included methods and attributes)
			if (classes.filter[container.ref == elem].length != 0){
				val classDistrict = cityFactory.createDistrict
				classDistrict.name = newDistrict.name + "_classDistrict"
				classDistrict.type = "classDistrict"
				classDistrict.level = level + 1
				classDistrict.id = elem.id + "_00004"
				if(elem.iteration >= 1){
					classDistrict.notInOrigin = "true"
				}
				
				classes.filter[container.ref === elem].forEach[classDistrict.entities += toBuilding(level + 2)]
				newDistrict.entities.add(classDistrict)
			}
			
			//Function Group (+function Modules)
			if (functionGroups.filter[container.ref == elem].length != 0){
				val functionGroupDistrict = cityFactory.createDistrict
				functionGroupDistrict.name = newDistrict.name + "_functionGroupDistrict"
				functionGroupDistrict.type = "functionGroupDistrict"
				functionGroupDistrict.level = level + 1
				functionGroupDistrict.id = elem.id + "_00005"
				if(elem.iteration >= 1){
					functionGroupDistrict.notInOrigin = "true"
				}
				
				functionGroups.filter[container.ref === elem].forEach[functionGroupDistrict.entities += toBuilding(level + 2)]
				newDistrict.entities.add(functionGroupDistrict)
			}
			
			//DB Tables - only if we need own district
			if(config.showOwnTablesDistrict){
				if (tables.filter[container.ref == elem].length != 0){
					val tableDistrict = cityFactory.createDistrict
					tableDistrict.name = newDistrict.name + "_tableDistrict"
					tableDistrict.type = "tableDistrict"
					tableDistrict.level = level + 1
					tableDistrict.id = elem.id + "_00006"
					if(elem.iteration >= 1){
						tableDistrict.notInOrigin = "true"
					}
					
					tables.filter[container.ref == elem].forEach[tableDistrict.entities += toBuilding(level + 2)]
					newDistrict.entities.add(tableDistrict)
				}
			}
							
		} else { // Start test mode
			if(dataElements.filter[container.ref == elem].length != 0){
				val dcDataDistrict = cityFactory.createDistrict
				dcDataDistrict.name = newDistrict.name + "_dcDataDistrict"
				dcDataDistrict.type = "dcDataDistrict"
				dcDataDistrict.id = elem.id + "_00002"
				dcDataDistrict.level = level + 1
				if(elem.iteration >= 1){
					dcDataDistrict.notInOrigin = "true"
				}
				
				dataElements.filter[container.ref == elem].forEach[dcDataDistrict.entities += toBuilding(level + 2)]
				newDistrict.entities.add(dcDataDistrict)
			}
		}		
								
		
		cityDocument.entities += newDistrict
		return newDistrict
	}
	
	
	// Mode: advanced
	def private District toAdvancedDistrict(FAMIXNamespace elem, int level){
		val newDistrict = cityFactory.createDistrict
		newDistrict.name = elem.name
		newDistrict.value = elem.value
		newDistrict.fqn = elem.fqn
		newDistrict.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newDistrict.level = level
		newDistrict.id = elem.id
		if(elem.iteration >= 1){
			newDistrict.notInOrigin = "true"
		}
		
		
		cityDocument.entities += newDistrict
		return newDistrict
	}
	
	// Methods to build buildings
	
	def Building toBuilding(FAMIXReport elem, int level){
		val newBuilding = cityFactory.createBuilding
		newBuilding.name = elem.name
		newBuilding.value = elem.value
		newBuilding.fqn = elem.fqn
		newBuilding.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newBuilding.level = level
		newBuilding.id = elem.id
		newBuilding.methodCounter = formroutines.filter[parentType.ref == elem].length
		newBuilding.dataCounter = attributes.filter[parentType.ref === elem].length
		if(elem.iteration >= 1){
			newBuilding.notInOrigin = "true"
		}
		
		formroutines.filter[parentType.ref == elem].forEach[newBuilding.methods.add(toFloor)]
		if(config.showReportAttributes){
			newBuilding.dataCounter = attributes.filter[parentType.ref == elem].length
			attributes.filter[parentType.ref == elem].forEach[newBuilding.data.add(toChimney)]
		}
		
		return newBuilding
	}
	
	def Building toBuilding(FAMIXFunctionGroup elem, int level){
		val newBuilding = cityFactory.createBuilding
		newBuilding.name = elem.name
		newBuilding.value = elem.value
		newBuilding.fqn = elem.fqn
		newBuilding.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newBuilding.level = level
		newBuilding.id = elem.id
		newBuilding.methodCounter = functionModules.filter[parentType.ref == elem].length
		newBuilding.dataCounter = attributes.filter[parentType.ref === elem].length
		if(elem.iteration >= 1){
			newBuilding.notInOrigin = "true"
		}
		
		functionModules.filter[parentType.ref == elem].forEach[newBuilding.methods.add(toFloor)]
		if(config.showFugrAttributes){
			newBuilding.dataCounter = attributes.filter[parentType.ref == elem].length
			attributes.filter[parentType.ref == elem].forEach[newBuilding.data.add(toChimney)]
		}
		
		return newBuilding
	}
	
	def Building toBuilding(FAMIXDictionaryData elem, int level){
		val newBuilding = cityFactory.createBuilding
		newBuilding.name = elem.name
		newBuilding.value = elem.value
		newBuilding.fqn = elem.fqn
		newBuilding.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newBuilding.level = level
		newBuilding.id = elem.id
		//newBuilding.dataCounter = 1  //- width/length
		if(elem.iteration >= 1){
			newBuilding.notInOrigin = "true"
		}
		
		//ABAPStruc segments
		if(newBuilding.type == "FAMIX.ABAPStruc"){
			newBuilding.methodCounter = abapStrucElem.filter[container.ref == elem].length
			abapStrucElem.filter[container.ref == elem].forEach[newBuilding.methods.add(toFloor(newBuilding.id))]
		}
		
		//TableType segments
		if(newBuilding.type == "FAMIX.TableType"){
			val tableTypeOf = typeOf.filter[element.ref == elem]

			for (tty : tableTypeOf){
				if(tty.typeOf.ref instanceof FAMIXABAPStruc){
					newBuilding.methodCounter = abapStrucElem.filter[container.ref == tty.typeOf.ref].length
					abapStrucElem.filter[container.ref == tty.typeOf.ref].forEach[newBuilding.methods.add(toFloor(newBuilding.id))]
				
				}else if(tty.typeOf.ref instanceof FAMIXTable){
					newBuilding.methodCounter = tableElements.filter[container.ref == tty.typeOf.ref].length
					tableElements.filter[container.ref == tty.typeOf.ref].forEach[newBuilding.methods.add(toFloor(newBuilding.id))]
				}
			}	
		}
		
		//Table segments
		if(newBuilding.type == "FAMIX.Table"){
			newBuilding.methodCounter = tableElements.filter[container.ref == elem].length
			tableElements.filter[container.ref == elem].forEach[newBuilding.methods.add(toFloor(newBuilding.id))]
		}
		
		return newBuilding
	}
	
	def private Building toBuilding(FAMIXClass elem, int level) {
		val newBuilding = cityFactory.createBuilding
		newBuilding.name = elem.name
		newBuilding.value = elem.value
		newBuilding.fqn = elem.fqn
		newBuilding.type = CityUtils.getFamixClassString(elem.class.simpleName)
		if(elem.iteration >= 1){
			newBuilding.notInOrigin = "true"
		}
		
		// Is interface?
		if(elem.isInterface == "true") {
			newBuilding.type = "FAMIX.Interface"
		}else{
			newBuilding.type = "FAMIX.Class"
		}

		newBuilding.level = level
		newBuilding.id = elem.id

		inheritances.filter[subclass.ref === elem].forEach [ i |
			val inheritance = cityFactory.createReference
			inheritance.type = "Inheritance"
			inheritance.name = i.superclass.ref.name
			inheritance.fqn = i.superclass.ref.fqn
			newBuilding.references += inheritance
		]

		newBuilding.dataCounter = methods.filter[parentType.ref === elem].length
		newBuilding.methodCounter = attributes.filter[parentType.ref === elem].length

		if (config.buildingType == BuildingType::CITY_FLOOR) {
			methods.filter[parentType.ref.equals(elem)].forEach[newBuilding.methods.add(toFloor)]
			attributes.filter[parentType.ref.equals(elem)].forEach[newBuilding.data.add(toChimney)]
		} 
		return newBuilding
	}

	/**
	 * Sets values for current class and searches for nested elements
	 * 
	 * @param elem Source class for the building
	 * @param level Hierarchy level of the building
	 * @return new Building
	 */
	def private Building toBuilding(FAMIXStructure elem, int level) {
		val newBuilding = cityFactory.createBuilding
		newBuilding.name = elem.name
		newBuilding.value = elem.value
		newBuilding.fqn = elem.fqn
		newBuilding.type = CityUtils.getFamixClassString(elem.class.simpleName)
		
		newBuilding.level = level
		newBuilding.id = elem.id
		inheritances.filter[subclass.ref === elem].forEach [ i |
			val inheritance = cityFactory.createReference
			inheritance.type = "Inheritance"
			inheritance.name = i.superclass.ref.name
			inheritance.fqn = i.superclass.ref.fqn
			newBuilding.references += inheritance
		]


		newBuilding.dataCounter = methods.filter[parentType.ref === elem].length
		newBuilding.methodCounter = attributes.filter[parentType.ref === elem].length

		if (config.buildingType == BuildingType::CITY_FLOOR) {
			methods.filter[parentType.ref.equals(elem)].forEach[newBuilding.methods.add(toFloor)]
			attributes.filter[parentType.ref.equals(elem)].forEach[newBuilding.data.add(toChimney)]
		}
		return newBuilding
	}

	def private Building toBuilding(FAMIXMethod elem, District parent, int level) {
		val newBuilding = cityFactory.createBuilding
		newBuilding.name = elem.name
		newBuilding.value = elem.value
		newBuilding.fqn = elem.fqn
		newBuilding.signature = elem.signature
		newBuilding.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newBuilding.level = level
		newBuilding.id = elem.id
		if(elem.iteration >= 1){
			newBuilding.notInOrigin = "true"
		}

		return newBuilding
	}
	
	/**
	 * Sets values for current method of the {@code parent} class.
	 * 
	 * @param elem Source method for the buildingSegment
	 * @param level Hierarchy level of the underlying district/package
	 * @return new BuildingSegment
	 * @see toBuildingSegment_Attribute(FAMIXAttribute, Building, int)
	 */
	def private BuildingSegment toBuildingSegment_Method(FAMIXMethod elem, Building parent, int level) {
		val newBuildingSegment = cityFactory.createBuildingSegment
		newBuildingSegment.name = elem.name
		newBuildingSegment.value = elem.value
		newBuildingSegment.fqn = elem.fqn
		newBuildingSegment.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newBuildingSegment.level = level
		newBuildingSegment.id = elem.id
		newBuildingSegment.signature = elem.signature
		newBuildingSegment.modifiers = elem.modifiers.toString
		newBuildingSegment.numberOfStatements = elem.numberOfStatements
		newBuildingSegment.parent = parent
		newBuildingSegment.methodKind = elem.kind
		newBuildingSegment.declaredType = CityUtils.fillDeclaredType(cityFactory.createDeclaredType, elem.declaredType)

		newBuildingSegment.localVariableCounter = localVariables.filter[parentBehaviouralEntity.ref === elem].length

		newBuildingSegment.parameterCounter = parameters.filter[parentBehaviouralEntity.ref === elem].length

		return newBuildingSegment
	}

	/**
	 * Sets values for current attribute of the {@code parent} class.
	 * 
	 * @param elem Source method for the buildingSegment
	 * @param level Hierarchy level of the underlying district/package
	 * @return new BuildingSegment
	 * @see toBuildingSegment_Method(FAMIXMethod, Building, int)
	 */
	def private BuildingSegment toBuildingSegment_Attribute(FAMIXAttribute elem, Building parent, int level) {
		val newBuildingSegment = cityFactory.createBuildingSegment
		newBuildingSegment.name = elem.name
		newBuildingSegment.value = elem.value
		newBuildingSegment.fqn = elem.fqn
		newBuildingSegment.type = CityUtils.getFamixClassString(elem.class.simpleName)
		newBuildingSegment.level = level
		newBuildingSegment.id = elem.id
		newBuildingSegment.modifiers = elem.modifiers.toString
		newBuildingSegment.parent = parent
		newBuildingSegment.declaredType = CityUtils.fillDeclaredType(cityFactory.createDeclaredType, elem.declaredType)

		return newBuildingSegment
	}

	// pko 2016
	def BuildingSegment create newBuildingSegment: cityFactory.createBuildingSegment toFloor(FAMIXMethod famixMethod) {
		newBuildingSegment.name = famixMethod.name
		newBuildingSegment.value = famixMethod.value
		newBuildingSegment.fqn = famixMethod.fqn
		newBuildingSegment.id = famixMethod.id
	}

	// pko 2016
	def BuildingSegment create newBuildingSegment: cityFactory.createBuildingSegment toChimney(
		FAMIXAttribute famixAttribute) {
		newBuildingSegment.name = famixAttribute.name
		newBuildingSegment.value = famixAttribute.value
		newBuildingSegment.fqn = famixAttribute.fqn
		newBuildingSegment.id = famixAttribute.id
	}
	
	
	//ABAP
	def BuildingSegment create newBuildingSegment: cityFactory.createBuildingSegment toFloor(FAMIXFormroutine famixFormroutine) {
		newBuildingSegment.name = famixFormroutine.name
		newBuildingSegment.value = famixFormroutine.value
		newBuildingSegment.fqn = famixFormroutine.fqn
		newBuildingSegment.id = famixFormroutine.id
	} 
	
	def BuildingSegment create newBuildingSegment: cityFactory.createBuildingSegment toFloor(FAMIXFunctionModule famixFuncModule) {
		newBuildingSegment.name = famixFuncModule.name
		newBuildingSegment.value = famixFuncModule.value
		newBuildingSegment.fqn = famixFuncModule.fqn
		newBuildingSegment.id = famixFuncModule.id
	} 
	
	def BuildingSegment create newBuildingSegment: cityFactory.createBuildingSegment toFloor(FAMIXStrucElement famixStrucElem, String buildingId) {
		newBuildingSegment.name = famixStrucElem.name
		newBuildingSegment.value = famixStrucElem.value
		newBuildingSegment.fqn = famixStrucElem.fqn
		newBuildingSegment.id = createID(famixStrucElem.id + "_" + buildingId)
	}

	def BuildingSegment create newBuildingSegment: cityFactory.createBuildingSegment toFloor(FAMIXTableElement famixTableElement, String buildingId) {
		newBuildingSegment.name = famixTableElement.name
		newBuildingSegment.value = famixTableElement.value
		newBuildingSegment.fqn = famixTableElement.fqn
		newBuildingSegment.id = createID(famixTableElement.id + "_" + buildingId)
	} 
	
	def createID(String fqn) {
		return "ID_" + sha1Hex(fqn + config.repositoryName + config.repositoryOwner)
	}
}