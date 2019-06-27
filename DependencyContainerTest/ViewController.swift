//
//  ViewController.swift
//  DependencyContainerTest
//
//  Created by Sofia on 25/06/2019.
//  Copyright © 2019 SonyaTest. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let container = DependencyContainer()
        
        container.register(type: IService1.self, singleton: true) { _ in Service1() }
        container.register(type: IService2.self, singleton: false) { resolver in
            Service2(service1: resolver.resolve(for: IService1.self))
        }
        
        let service2 = container.resolve(for: IService2.self)
        let service21 = container.resolve(for: IService2.self)
    }


}

protocol IService1 { }

class Service1: IService1 {
    init() {
        print("Service 1 initialized")
    }
}

protocol IService2 { var service1: IService1 { get set } }

class Service2: IService2 {
    var service1: IService1
    
    init(service1: IService1) {
        self.service1 = service1
    }
}

protocol IResolver {
    func resolve<Service>(for type: Service.Type) -> Service
}

protocol IRegistrator {
    func register<Service>(type: Service.Type, singleton: Bool, instantiateAction: @escaping (IResolver) -> (Service))
}

class DependencyContainer {
    private struct CreateServiceParameters {
        let singleton: Bool
        let instantiateAction: (DependencyContainer) -> Any
    }
    
    private struct ServiceKey: Hashable, Equatable {
        let type: Any.Type
        var name: String {
            return String(describing: type)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(name)
        }

        static func == (lhs: DependencyContainer.ServiceKey, rhs: DependencyContainer.ServiceKey) -> Bool {
            return lhs.name == rhs.name
        }
    }
    
    private var container: [ServiceKey: CreateServiceParameters] = [:]
    private var singletons: [ServiceKey: Any] = [:]
}

extension DependencyContainer: IResolver {
    func resolve<Service>(for type: Service.Type) -> Service {
        let key = ServiceKey(type: type)
        guard let object = container[key] else { fatalError("\(type) wasn't register in container") }
        
        if object.singleton {
            if let objectInstance = singletons[key] as? Service {
                return objectInstance
            }
        }
        guard let objectInstance = object.instantiateAction(self) as? Service else { fatalError("\(type) dependencies cannot be resolved") }
        if object.singleton {
            singletons[key] = objectInstance
        }
        
        return objectInstance
    }
}

extension DependencyContainer: IRegistrator {
    func register<Service>(type: Service.Type, singleton: Bool, instantiateAction: @escaping (IResolver) -> Service) {
        let service = ServiceKey(type: type)
        let object = CreateServiceParameters(singleton: singleton, instantiateAction: instantiateAction)
        container[service] = object
    }
}


