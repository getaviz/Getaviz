package org.svis.generator.rd.s2m

import java.util.List
import java.util.Set
import org.apache.commons.logging.LogFactory
import org.eclipse.emf.mwe.core.WorkflowContext
import org.eclipse.emf.mwe.core.issues.Issues
import org.eclipse.emf.mwe.core.monitor.ProgressMonitor
import org.svis.generator.rd.RDSettings
import org.svis.xtext.hismo.HISMOAttributeHistory
import org.svis.xtext.hismo.HISMOClassHistory
import org.svis.xtext.hismo.HISMOClassVersion
import org.svis.xtext.hismo.HISMOMethodHistory
import org.svis.xtext.hismo.HISMONamespaceHistory
import org.svis.xtext.hismo.HISMONamespaceVersion
import org.svis.xtext.hismo.HismoDocument
import org.svis.xtext.hismo.HismoRoot
import org.svis.xtext.rd.Disk
import org.svis.xtext.rd.DiskSegment
import org.svis.xtext.rd.Document
import org.svis.xtext.rd.impl.RdFactoryImpl
import org.svis.xtext.hismo.HISMOMethodVersion
import org.svis.xtext.hismo.HISMOAttributeVersion
import org.svis.xtext.rd.DiskVersion
import org.svis.xtext.rd.Version
import org.eclipse.emf.mwe.core.lib.WorkflowComponentWithModelSlot
import org.apache.commons.beanutils.BeanComparator
import org.svis.xtext.famix.FAMIXAttribute
import org.svis.xtext.famix.FAMIXClass
import org.svis.xtext.famix.FAMIXEnumValue
import org.svis.xtext.famix.FAMIXInheritance
import org.svis.xtext.famix.FAMIXMethod
import org.svis.xtext.famix.FAMIXNamespace
import org.svis.xtext.famix.FAMIXStructure
import org.svis.generator.famix.Famix2Famix
import org.svis.generator.rd.RDSettings.EvolutionRepresentation
import org.eclipse.emf.ecore.resource.impl.ResourceImpl
import org.svis.xtext.famix.FAMIXFileAnchor
import java.util.ArrayList
import org.svis.generator.hismo.HismoUtils
import org.svis.generator.FamixUtils
import org.svis.generator.rd.RDSettings.ShowVersions

class Hismo2RD extends WorkflowComponentWithModelSlot {
	val static diskFactory = new RdFactoryImpl()
	var HismoDocument hismoDocument
	var Document diskDocument
	val log = LogFactory::getLog(class)
	val famix = new Famix2Famix
	extension FamixUtils famixUtil = new FamixUtils
	extension HismoUtils hismoUtil = new HismoUtils
	val nameComparator = new BeanComparator("name")
	val Set<HISMONamespaceHistory> hismoPackages = newTreeSet(nameComparator)
	val Set<HISMONamespaceVersion> hismoPackageVersions = newTreeSet(nameComparator)
	val Set<HISMOClassVersion> hismoClassVersions = newTreeSet(nameComparator)
	val Set<HISMOClassVersion> latestClassVersions = newTreeSet(nameComparator)
	val Set<HISMOMethodVersion> hismoMethodVersions = newTreeSet(nameComparator)
	val Set<HISMOAttributeVersion> hismoAttributeVersions = newTreeSet(nameComparator)
	val Set<HISMONamespaceHistory> hismoRootPackages = newTreeSet(nameComparator)
	val Set<HISMONamespaceHistory> hismoSubPackages = newTreeSet(nameComparator)
	val Set<HISMOClassHistory> hismoClasses = newTreeSet(nameComparator)
	val Set<HISMOMethodHistory> hismoMethods = newTreeSet(nameComparator)
	val Set<HISMOAttributeHistory> hismoAttributes = newTreeSet(nameComparator)
	val List<FAMIXNamespace> rootPackages = newArrayList
	val List<FAMIXNamespace> subPackages = newArrayList
	val List<FAMIXStructure> structures = newArrayList
	val List<FAMIXMethod> methods = newArrayList
	val List<FAMIXAttribute> attributes = newArrayList
	val List<FAMIXEnumValue> enumValues = newArrayList
	val List<FAMIXInheritance> inheritances = newArrayList
	val List<String> sortedtimestamps = newLinkedList
	// TODO solve it with injection
	// @Inject extension XtendUtils util
	
	override protected invokeInternal(WorkflowContext ctx, ProgressMonitor monitor, Issues issues) {
		log.info("Hismo2RD has started")
		var hismoRoot = ctx.get("hismo") as List<HismoRoot>
		hismoDocument = hismoRoot.head.hismoDocument
		
		hismoClassVersions += hismoDocument.elements.filter(HISMOClassVersion)
		hismoPackageVersions += hismoDocument.elements.filter(HISMONamespaceVersion)
		val Set<String> timestamps = newHashSet
		if(RDSettings::SHOW_CLASS_MEMBERS) {
			hismoMethodVersions += hismoDocument.elements.filter(HISMOMethodVersion)
			hismoAttributeVersions += hismoDocument.elements.filter(HISMOAttributeVersion)
			timestamps += hismoAttributeVersions.map[timestamp]
			timestamps += hismoMethodVersions.map[timestamp]
		}
		timestamps += hismoClassVersions.map[timestamp]
		timestamps += hismoPackageVersions.map[timestamp]

		sortedtimestamps.addAll(timestamps.toList.sort)
		
		val diskList = newArrayList
		if(RDSettings::EVOLUTION_REPRESENTATION == EvolutionRepresentation::TIME_LINE
			|| RDSettings::EVOLUTION_REPRESENTATION == EvolutionRepresentation::DYNAMIC_EVOLUTION) {
			val diskRoot = createRoot
			fillLists()
			hismoPackages.forEach[it.packages]
			hismoRootPackages.forEach[it.toDisk(1)]	
			removeUnnecessaryFamixElements(hismoRoot)
			diskList += diskRoot
		} else {
			for (timestamp: sortedtimestamps) {
				val diskRoot = createRoot
				fillLists(timestamp)
				rootPackages.forEach[toDisk(1, timestamp)]
				removeUnnecessaryHismoElements(hismoRoot)
				diskList += diskRoot		
			}
		}
		if(RDSettings::SHOW_VERSIONS == ShowVersions::LATEST) {
			hismoClassVersions.clear
			hismoClassVersions.addAll(latestClassVersions)
		}
		val resource = new ResourceImpl()
		resource.contents += hismoRoot
		ctx.set("metadata", resource)	
		// put diskroot into list (for writer)
		ctx.set("rdwriter", diskList)		
		// put diskroot into slot (for rd2rd)
		ctx.set("rd", diskList)
			
		log.info("Hismo2RD has finished.")
	}
	
	def private createRoot() {
		val diskRoot = diskFactory.createRoot
		diskDocument = diskFactory.createDocument
		diskRoot.document = diskDocument
		return diskRoot
	}	
	
	def private removeUnnecessaryFamixElements(List<HismoRoot> hismoroot){
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(FAMIXNamespace))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(FAMIXClass))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(FAMIXMethod))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(FAMIXAttribute))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(FAMIXFileAnchor))
	}
	
	def private removeUnnecessaryHismoElements(List<HismoRoot> hismoroot){
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMONamespaceVersion))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMOClassVersion))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMOMethodVersion))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMOAttributeVersion))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMONamespaceHistory))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMOClassHistory))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMOMethodHistory))
		hismoDocument.elements.removeAll(hismoDocument.elements.filter(HISMOAttributeHistory))
	}
	
	def private fillLists() {
		hismoClasses += hismoDocument.elements.filter(HISMOClassHistory)
		hismoPackages += hismoDocument.elements.filter(HISMONamespaceHistory)
		hismoMethods += hismoDocument.elements.filter(HISMOMethodHistory)
		hismoAttributes += hismoDocument.elements.filter(HISMOAttributeHistory)
	}

	def private fillLists(String timestamp) {
		rootPackages.clear
		rootPackages += hismoDocument.elements
			.filter(FAMIXNamespace)
			.filter[parentScope === null]
			.filter[pack|hismoPackageVersions.exists[
				it.timestamp == timestamp && it.versionEntity.ref === pack  
			]]
		subPackages.clear
		subPackages += hismoDocument.elements
			.filter(FAMIXNamespace)
			.filter[parentScope !== null]
			.filter[pack|hismoPackageVersions.exists[
				it.timestamp == timestamp && it.versionEntity.ref === pack  
			]]
		structures.clear
		structures += hismoDocument.elements
			.filter(FAMIXStructure)
			.filter[class|hismoClassVersions.exists[
				it.timestamp == timestamp && it.versionEntity.ref === class  
			]]
		methods.clear				
		methods += hismoDocument.elements
			.filter(FAMIXMethod)
			.filter[method|hismoMethodVersions.exists[
				it.timestamp == timestamp && it.versionEntity.ref === method  
			]]
		attributes.clear				
		attributes += hismoDocument.elements
			.filter(FAMIXAttribute)
			.filter[attribute|hismoAttributeVersions.exists[
				it.timestamp == timestamp && it.versionEntity.ref === attribute  
			]]
	}
	
	def private void getPackages(HISMONamespaceHistory namespace) {
		if (namespace.containingNamespaceHistory === null) {
			val SubPacks = new ArrayList<HISMONamespaceHistory>
			hismoPackages.filter[containingNamespaceHistory !== null]
						.filter[containingNamespaceHistory.ref === namespace].forEach[
							SubPacks += it
						]
			if (!SubPacks.empty || !namespace.classHistories.empty) {
          		hismoRootPackages += namespace
      		} 
		} else {
			hismoSubPackages += namespace
		}
	}

	def private Disk toDisk(HISMONamespaceHistory hismoNamespace, int level) {
		val disk = diskFactory.createDisk
		disk.name = hismoNamespace.name
		disk.value = hismoNamespace.name//hismoNamespace.value
		disk.fqn = hismoNamespace.qualifiedName
		disk.fqn = hismoNamespace.value
		disk.type = "FAMIX.Namespace"
		disk.level = level
		disk.ringWidth = RDSettings::RING_WIDTH
		disk.id = famix.createID(disk.fqn)
		disk.height = RDSettings::HEIGHT
		disk.transparency = RDSettings::NAMESPACE_TRANSPARENCY
		
		switch(RDSettings::SHOW_VERSIONS) {
			case ShowVersions::LATEST: {
				hismoClassVersions
				.filter[(parentHistory.ref as HISMOClassHistory).containingNamespaceHistory.ref === hismoNamespace]
				.groupBy[name].forEach[name, list|
					val version = list.sortBy[timestamp].last
					disk.disks += version.toDisk(level+1)
					latestClassVersions += version
				]
			}
			case ShowVersions::ALL: {
				hismoClasses.filter[containingNamespaceHistory.ref === hismoNamespace].forEach[
					disk.disks += it.toDisk(level + 1)
				]
				
	 			hismoPackageVersions.filter[parentHistory.ref === hismoNamespace].forEach[
	 				disk.diskVersions += it.toDiskVersion
	 			]
			}
		}
		
		hismoSubPackages.filter[containingNamespaceHistory.ref === hismoNamespace].forEach[
			disk.disks += it.toDisk(level + 1)
		]

		diskDocument.disks += disk
		return disk
	}
	
	def private Disk toDisk(HISMOClassVersion classVersion, int level) {
		val disk = diskFactory.createDisk
		disk.name = classVersion.name
		disk.value = classVersion.name
		disk.fqn = classVersion.name
		disk.type = "FAMIX.Class"
		disk.level = level
		disk.id = famix.createID(disk.fqn)
		
		val history = classVersion.parentHistory.ref as HISMOClassHistory
		
		switch(RDSettings::CLASS_HEIGHT) {
			case STATIC: disk.height = RDSettings::HEIGHT
			case NUMBER_OF_INCIDENTS: {
				val sum = history.avgNumberOfOpenIncidents + history.avgNumberOfClosedIncidents + history.numberOfOpenSecurityIncidents + history.numberOfClosedSecurityIncidents
				if(sum < RDSettings::HEIGHT) {
					disk.height = RDSettings::HEIGHT
				} else {
					disk.height = sum
				}
			}
		}
		disk.transparency = RDSettings::CLASS_TRANSPARENCY
		switch(RDSettings::CLASS_SIZE) {
			case BETWEENNESS_CENTRALITY: disk.ringWidth = Double.parseDouble(classVersion.betweennessCentrality) * 100
			case NUMBER_OF_STATEMENTS: disk.ringWidth = classVersion.NOS / 100
		}

		switch(RDSettings::CLASS_COLOR_METRIC) {
			case STK: disk.color = famixUtil.getGradient(Double.parseDouble(classVersion.stkRank)).asPercentage
			case STATIC: disk.color = RDSettings::CLASS_COLOR
			case CHANGE_FREQUENCY: {
				 val max = hismoClasses.map[h|h.classVersions.size].max
				 val abc = history.classVersions.size * 1.0/max
				 disk.color = famixUtil.getBlueGradient(abc).asPercentage
			}
		}
		
		return disk
	}
	
	def private DiskVersion toDiskVersion(HISMONamespaceVersion version) {
		val diskVersion = diskFactory.createDiskVersion
		diskVersion.height = sortedtimestamps.indexOf(version.timestamp) * RDSettings::HEIGHT_BOOST
		diskVersion.level =sortedtimestamps.indexOf(version.timestamp) 
		diskVersion.commitId = version.commitId
		diskVersion.author = version.author
		diskVersion.timestamp = version.timestamp
		diskVersion.name = version.name
		diskVersion.scale = 1
		diskVersion.id = version.id
		diskVersion.ringWidth = RDSettings::RING_WIDTH
		diskVersion.color = RDSettings::NAMESPACE_COLOR
		
		return diskVersion		
	}

	def private Disk toDisk(HISMOClassHistory hismoClass, int level) {
		val disk = diskFactory.createDisk
		disk.name = hismoClass.name
		disk.value = hismoClass.name
		disk.fqn = hismoClass.qualifiedName
		disk.type = "FAMIX.ClassH"
		disk.level = level
		switch(RDSettings::CLASS_SIZE) {
			case BETWEENNESS_CENTRALITY: disk.ringWidth =  getMaxNOS(hismoClass) * 10 
			case NUMBER_OF_STATEMENTS: disk.ringWidth = RDSettings::RING_WIDTH
			case NONE: disk.ringWidth = RDSettings::RING_WIDTH
		}
		if(disk.ringWidth == 0) { 
			disk.ringWidth = 1
		}
		
		disk.id = famix.createID(disk.fqn)
		disk.height = RDSettings::HEIGHT
		disk.color = RDSettings::CLASS_COLOR
		disk.transparency = RDSettings::CLASS_TRANSPARENCY
		
		// references
		/* TODO: implement
		for (i : hismoDocument.elements.filter(typeof(FAMIXInheritance)).filter[subclass.ref.equals(famixClass)].
			filterNull) {
			//println("Class (Inheritance): subclass "+ famixClass.value + " ("+famixClass.name+") " + "superclass " + i.superclass.ref  + " ("+i.superclass.ref.name+")")
			val inheritance = diskFactory.createReference
			inheritance.type = "Inheritance"
			inheritance.name = i.superclass.ref.name
			inheritance.fqn = i.superclass.ref.qualifiedName
			disk.references.add(inheritance)
		}
		 */
		hismoClasses.filter[containingNamespaceHistory.ref == hismoClass].forEach[disk.disks += toDisk(level + 1)]
		if(RDSettings::SHOW_CLASS_MEMBERS) {
			hismoAttributes.filter[containingClassHistory.ref === hismoClass].forEach[disk.data += toDiskSegment]
			hismoMethods.filter[containingClassHistory.ref === hismoClass].forEach[disk.methods += toDiskSegment(disk)]
		}
	  	hismoClassVersions.filter[parentHistory.ref === hismoClass].forEach[
	  		disk.diskVersions += toDiskVersion(it,hismoClass)
	  	]
		return disk
	}

	def private DiskVersion toDiskVersion(HISMOClassVersion classVersion,HISMOClassHistory history) {
		val diskversion = diskFactory.createDiskVersion
		diskversion.height = 50//sortedtimestamps.indexOf(classVersion.timestamp) * RDSettings::HEIGHT_BOOST
		diskversion.level = sortedtimestamps.indexOf(classVersion.timestamp) 
		diskversion.commitId = classVersion.commitId
		diskversion.author = classVersion.author
		diskversion.timestamp = classVersion.timestamp
		diskversion.name = classVersion.name
		diskversion.id = classVersion.id
		switch(RDSettings::CLASS_SIZE) {
			case BETWEENNESS_CENTRALITY: diskversion.ringWidth = Double.parseDouble(classVersion.betweennessCentrality) * 100
			case NUMBER_OF_STATEMENTS: diskversion.ringWidth = RDSettings::RING_WIDTH
		}
		switch(RDSettings::CLASS_COLOR_METRIC) {
			case STK: diskversion.color = famixUtil.getGradient(Double.parseDouble(classVersion.stkRank)).asPercentage
			case STATIC: diskversion.color = RDSettings::CLASS_COLOR
			
		}

		if (history.getMaxNOS() > 0 && classVersion.NOS > 0) {
			diskversion.scale = classVersion.NOS / history.maxNOS
		} else 	{
			diskversion.scale = 1
		}
		return diskversion
	}
	
	def private getMaxNOS(HISMOClassHistory history) {
		return hismoClassVersions.filter[
			parentHistory.ref === history
		].maxBy[NOS].NOS 
	}  
	
	def private getNOS(HISMOClassVersion version) {
		val classHistory = version.parentHistory.ref as HISMOClassHistory
		if(RDSettings::SHOW_CLASS_MEMBERS) {
			val mhRefs = newLinkedList
			var sum = 0.0
			classHistory.methodHistories.forEach[mhRefs += ref]
			val methodVersions = hismoMethodVersions.filter[
				timestamp == version.timestamp
			].filter[
				mhRefs.contains(parentHistory.ref)
			]
			for (methodVersion : methodVersions) {
				sum += methodVersion.evolutionNumberOfStatements
			}
			return sum
		} else {
			switch(RDSettings::CLASS_SIZE) {
				case BETWEENNESS_CENTRALITY: return Double.parseDouble(version.betweennessCentrality)
				case NUMBER_OF_STATEMENTS: {
					val sum = 500 + classHistory.classVersions.map[ref as HISMOClassVersion]
						.filter[it.timestamp <= version.timestamp]
						.map[evolutionNumberOfStatements].reduce[ a, b | a + b ]
					return sum
				}
			}
		}
	}

	def private DiskSegment toDiskSegment(HISMOMethodHistory hismoMethod, Disk disk) {
		val diskSegment = diskFactory.createDiskSegment
		diskSegment.name = hismoMethod.name
		diskSegment.value = hismoMethod.name
		diskSegment.fqn =  hismoMethod.qualifiedName //"AAA"//method.qualifiedName(parameters)
		diskSegment.signature = hismoMethod.signature
		diskSegment.id = famix.createID(diskSegment.fqn)
		diskSegment.height = RDSettings::HEIGHT
		diskSegment.color = RDSettings::METHOD_COLOR
		diskSegment.transparency = RDSettings::METHOD_TRANSPARENCY

		if (hismoMethod.maxNumberOfStatements  <= RDSettings::MIN_AREA) {
			diskSegment.size = RDSettings::MIN_AREA
		} else {
			diskSegment.size = hismoMethod.maxNumberOfStatements//method.numberOfStatements
		}
 	 	hismoMethodVersions.filter[parentHistory.ref === hismoMethod].forEach[
 	 		diskSegment.versions += toVersion(hismoMethod)
 	 	]
		return diskSegment
	}
	
	def private Version toVersion(HISMOMethodVersion methodVersion, HISMOMethodHistory history) {
		val version = diskFactory.createVersion
		version.height = sortedtimestamps.indexOf(methodVersion.timestamp) * RDSettings::HEIGHT_BOOST
		version.scale = methodVersion.evolutionNumberOfStatements*1.0/history.maxNumberOfStatements;
		version.level = sortedtimestamps.indexOf(methodVersion.timestamp)
		version.commitId = methodVersion.commitId
		version.author = methodVersion.author
		version.timestamp = methodVersion.timestamp
		version.name = methodVersion.name
		version.id = methodVersion.id
		return version
	}

	def private DiskSegment toDiskSegment(HISMOAttributeHistory attribute) {
		val diskSegment = diskFactory.createDiskSegment
		diskSegment.name = attribute.name
		diskSegment.value = attribute.name //attribute.value
		diskSegment.fqn = attribute.qualifiedName
		diskSegment.id = famix.createID(diskSegment.fqn)
		diskSegment.size = 1 //attribute.declaredType.ref.attributeSize
		diskSegment.height = RDSettings::HEIGHT
		diskSegment.color = RDSettings::DATA_COLOR
		diskSegment.transparency = RDSettings::DATA_TRANSPARENCY

   		hismoAttributeVersions.filter[parentHistory.ref === attribute].forEach[
   			diskSegment.versions += toVersion(attribute)
   		]
		return diskSegment		
	}

	def private Version toVersion(HISMOAttributeVersion attributeVersion, HISMOAttributeHistory history) {
		val version = diskFactory.createVersion
		version.height = sortedtimestamps.indexOf(attributeVersion.timestamp) * RDSettings::HEIGHT_BOOST
		version.level = sortedtimestamps.indexOf(attributeVersion.timestamp)
		version.commitId = attributeVersion.commitId
		version.author = attributeVersion.author
		version.timestamp = attributeVersion.timestamp
		version.scale = 1
		version.name = attributeVersion.name
		version.id = attributeVersion.id
		return version
	}

	def private Disk toDisk(FAMIXNamespace famixNamespace, int level, String timestamp) {
		val disk = diskFactory.createDisk
		disk.name = famixNamespace.name
		disk.value = famixNamespace.value
		disk.ringWidth = RDSettings::RING_WIDTH/2
		disk.height = RDSettings::HEIGHT
		disk.position = diskFactory.createPosition
		disk.position.z = sortedtimestamps.indexOf(timestamp) * RDSettings::HEIGHT_MULTIPLICATOR
		
		val nsh = hismoPackageVersions.findFirst[
			it.timestamp == timestamp && it.versionEntity.ref === famixNamespace  
		].parentHistory.ref as HISMONamespaceHistory
		
		disk.fqn = nsh.qualifiedNameMultiple
		disk.id = famix.createID(disk.fqn)
		disk.type = "FAMIX.Namespace"
		disk.transparency = RDSettings::NAMESPACE_TRANSPARENCY
		disk.level = level
		
		structures.filter[container.ref === famixNamespace]	.forEach[
			disk.disks += toDisk(level + 1, timestamp)
		]
			
		subPackages.filter[parentScope.ref === (famixNamespace)].forEach[
			disk.disks += toDisk(level + 1, timestamp)
		]

		hismoPackageVersions.filter[parentHistory.ref === nsh].filter[it.timestamp == timestamp].forEach[
			disk.diskVersion = it.toDiskVersion
		]
		diskDocument.disks += disk
		
		return disk
	}

	def private Disk toDisk(FAMIXStructure el, int level, String timestamp) {
		val disk = diskFactory.createDisk
		disk.name = el.name
		disk.value = el.value
		disk.ringWidth = RDSettings::RING_WIDTH
		disk.position = diskFactory.createPosition
		disk.position.z = sortedtimestamps.indexOf(timestamp) * RDSettings::HEIGHT_MULTIPLICATOR
		disk.height = RDSettings::HEIGHT
		disk.transparency = RDSettings::CLASS_TRANSPARENCY
		disk.color = RDSettings::CLASS_COLOR
		
		val ch = hismoClassVersions.findFirst[
			it.timestamp == timestamp && it.versionEntity.ref === el  
		].parentHistory.ref as HISMOClassHistory
		
		disk.fqn = ch.qualifiedNameMultiple
		disk.id = famix.createID(disk.fqn)
		disk.type = el.typeString
		disk.level = level
		
		inheritances.filter[subclass.ref === el].forEach[
			val inheritance = diskFactory.createReference
			inheritance.type = "Inheritance"
			inheritance.name = it.superclass.ref.name
			inheritance.fqn = it.superclass.ref.fqn
			disk.references += inheritance
		]
		
		attributes.filter[parentType.ref === el].forEach[disk.data += toDiskSegment(timestamp)]
		methods.filter[parentType.ref === el].forEach[disk.methods += toDiskSegment(timestamp)]
		structures.filter[container.ref === el].forEach[disk.disks += toDisk(level + 1, timestamp)]
		enumValues.filter[parentEnum.ref === el].forEach[disk.data += toDiskSegment(timestamp)]
		
		hismoClassVersions.filter[parentHistory.ref === ch].filter[it.timestamp == timestamp].forEach[
			disk.diskVersion = it.toDiskVersion(ch)
		]
		
		return disk
	}
	
	def private toDiskSegment(FAMIXMethod method, String timestamp) {
		val diskSegment = diskFactory.createDiskSegment
		diskSegment.name = method.name
		diskSegment.value = method.value
		diskSegment.height = RDSettings::HEIGHT
		diskSegment.color = RDSettings::METHOD_COLOR
		diskSegment.transparency = RDSettings::METHOD_TRANSPARENCY
		
		val mh = hismoMethodVersions.findFirst[
			it.timestamp == timestamp && it.versionEntity.ref === method  
		].parentHistory.ref as HISMOMethodHistory
		
		diskSegment.fqn = mh.qualifiedNameMultiple
		diskSegment.id = famix.createID(diskSegment.fqn)
		diskSegment.signature = method.signature

		if (method.numberOfStatements <= RDSettings::MIN_AREA) {
			diskSegment.size = RDSettings::MIN_AREA
		} else {
			diskSegment.size = method.numberOfStatements
		}
		hismoMethodVersions.filter[parentHistory.ref === mh].filter[it.timestamp == timestamp].forEach[
				diskSegment.version = it.toVersion(mh)
		]
		return diskSegment
	}
	
	def private toDiskSegment(FAMIXAttribute attribute, String timestamp) {
		val diskSegment = diskFactory.createDiskSegment
		diskSegment.name attribute.name
		diskSegment.value = attribute.value
		diskSegment.height = RDSettings::HEIGHT
		diskSegment.color = RDSettings::DATA_COLOR
		diskSegment.transparency = RDSettings::DATA_TRANSPARENCY	
	  	val history = hismoAttributeVersions.findFirst[
			it.timestamp == timestamp && it.versionEntity.ref === attribute
		].parentHistory.ref as HISMOAttributeHistory
		diskSegment.fqn = history.qualifiedNameMultiple
		diskSegment.id = famix.createID(diskSegment.fqn)
		diskSegment.size = 1 //attribute.declaredType.ref.attributeSize
		val versions = hismoAttributeVersions.filter[parentHistory.ref === history]
		
		versions.filter[it.timestamp == timestamp].forEach[
			diskSegment.version = it.toVersion(history)
		]
		return diskSegment
	}	

	def private toDiskSegment(FAMIXEnumValue enumValue, String timestamp) {
		val diskSegment = diskFactory.createDiskSegment
		diskSegment.name = enumValue.name
		diskSegment.value = enumValue.value
		diskSegment.fqn = enumValue.fqn
		diskSegment.id = famix.createID(diskSegment.fqn)
		diskSegment.size = 1 // TODO size
		diskSegment.height = RDSettings::HEIGHT
		diskSegment.color = RDSettings::DATA_COLOR
		diskSegment.transparency = RDSettings::DATA_TRANSPARENCY
		return diskSegment
	}
}