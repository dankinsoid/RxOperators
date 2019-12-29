//
//  Subscrition.swift
//  Pods
//
//  Created by Daniil on 21.08.2019.
//

import RxSwift

public protocol SubscritionObserverType {
    associatedtype Element
    func on(event: Event<Element>, in subscrition: Subscrition)
}

public protocol SubscritionObservableType {
    associatedtype Element
    func subscribe<O: SubscritionObserverType>(observer: O) -> Subscrition where O.Element == Element
}

public final class Subscrition: Cancelable, Hashable {
    public var isDisposed: Bool { return disposable.isDisposed }
    private var disposable: Cancelable
    
    public init(_ disposable: Disposable) {
        self.disposable = Disposables.create([disposable])
    }
    
    public init(_ block: @escaping (Subscrition) -> () = {_ in }) {
        disposable = Disposables.create {}
        disposable = Disposables.create(with: {[unowned self] in block(self) })
    }
    
    public static func ==(lhs: Subscrition, rhs: Subscrition) -> Bool {
        return lhs === rhs
    }
    
    public func dispose() {
        disposable.dispose()
    }
    
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
    
}

final class O<Element>: SubscritionObserverType, SubscritionObservableType {
    
    private var _value: Element
    private var observers: [Subscrition: AnyObserver<Element>] = [:]
    
    init(_ value: Element) {
        _value = value
    }
    
    func on(event: Event<Element>, in subscrition: Subscrition) {
        if case .next(let new) = event {
            _value = new
            observers.forEach {
                guard $0.key != subscrition else { return }
                $0.value.on(event)
            }
        }
    }
    
    func subscribe<O: SubscritionObserverType>(observer: O) -> Subscrition where Element == O.Element {
        let result = Subscrition {[weak self] in
            self?.observers[$0] = nil
        }
        observers[result] = observers
        return result
    }
    
}
