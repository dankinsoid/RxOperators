//
//  Rx++.swift
//  MusicImport
//
//  Created by Данил Войдилов on 21.06.2019.
//  Copyright © 2019 Данил Войдилов. All rights reserved.
//

import RxSwift
import RxCocoa
import VDKit

extension PrimitiveSequenceType where Self.Trait == SingleTrait {
	
	public func subscribe(_ completion: @escaping (Result<Self.Element, Error>) -> ()) -> Disposable {
		return self.subscribe(
			onSuccess: { completion(.success($0)) },
			onError: { completion(.failure($0)) }
		)
	}
	
}

extension NSNotification.Name {
	
	public var rx: Observable<Notification> {
		return NotificationCenter.default.rx.notification(self)
	}
	
}

extension ObservableType where Element: OptionalProtocol {
	
	public func skipNil() -> Observable<Element.Wrapped> {
		return map({ $0.asOptional() }).filter({ $0 != nil }).map({ $0! })
	}
	
}

extension ObservableType where Element == Bool? {
	
	public func or(_ value: Bool) -> Observable<Bool> {
		return map({ $0 ?? value })
	}
	
}

extension ObservableType where Element == Bool {
	
	public func toggle() -> Observable<Bool> {
		return map({ !$0 })
	}
	
}

extension NSRecursiveLock {
    
    func protect(code: () -> ()) {
        lock()
        code()
        unlock()
    }
    
    func protect<T>(code: () -> T) -> T {
        lock()
        defer { unlock() }
        return code()
    }
}

extension NSLock {
    
    func protect(code: () -> ()) {
        lock()
        code()
        unlock()
    }
    
    func protect<T>(code: () -> T) -> T {
        lock()
        defer { unlock() }
        return code()
    }
}

extension ObservableType {
    
    public func asDriver() -> Driver<Element> {
        return asDriver(onErrorDriveWith: .never())
    }
    
}

public struct WeakRef<T: AnyObject, Element>: ObserverType {
    public weak var object: T?
    public let keyPath: ReferenceWritableKeyPath<T, Element>
    
    public func on(_ event: Event<Element>) {
        if case .next(let value) = event {
            object?[keyPath: keyPath] = value
        }
    }
    
}

public struct WeakMethod<T: AnyObject, Element>: ObserverType {
    public weak var object: T?
    public let method: (T) -> (Element) -> ()
    
    public func on(_ event: Event<Element>) {
        if let obj = object, case .next(let value) = event {
            method(obj)(value)
        }
    }
    
}

extension Reactive where Base: AnyObject {
    
    public func keyPath<Element>(_ keyPath: ReferenceWritableKeyPath<Base, Element>) -> AnyObserver<Element> {
        return WeakRef(object: base, keyPath: keyPath).asObserver()
    }
    
    public func weak<E>(method: @escaping (Base) -> (E) -> ()) -> AnyObserver<E> {
        return WeakMethod(object: base, method: method).asObserver()
    }
    
    public func weak(method: @escaping (Base) -> () -> ()) -> AnyObserver<Void> {
        return WeakMethod(object: base, method: { b in {_ in method(b)() } }).asObserver()
    }
    
}

extension ObservableType {
    
    public func map<B: AnyObject, T>(_ method:  @escaping (B) -> (Element) -> T, on object: B) -> Observable<T> {
        return compactMap {[weak object] in
            guard let obj = object else { return nil }
            return method(obj)($0)
        }
    }
    
}

public func +<T: ObservableType, O: ObservableType>(_ lhs: T, _ rhs: O) -> Observable<O.Element> where O.Element == T.Element {
    return Observable.merge([lhs.asObservable(), rhs.asObservable()])
}

public func +<T: ObserverType, O: ObserverType>(_ lhs: T, _ rhs: O) -> AnyObserver<O.Element> where O.Element == T.Element {
    let o1 = lhs.asObserver()
    let o2 = rhs.asObserver()
    return AnyObserver {
        o1.on($0)
        o2.on($0)
    }
}

public func +(_ lhs: Disposable, _ rhs: Disposable) -> Cancelable {
    return Disposables.create(lhs, rhs)
}

public func +=<O: ObservableType>(_ lhs: inout Observable<O.Element>, _ rhs: O) {
    lhs = Observable.merge([lhs.asObservable(), rhs.asObservable()])
}

public func +=<O: ObserverType>(_ lhs: inout AnyObserver<O.Element>, _ rhs: O) {
    lhs = lhs + rhs
}

public func +=<O: Disposable>(_ lhs: inout Cancelable, _ rhs: O) {
    lhs = lhs + rhs
}

//public func +<A: ObservableType, B: ObservableType>(_ lhs: A, _ rhs: B) -> Observable<(A.E, B.Element)> {
//    return Observable.combineLatest(lhs, rhs) { ($0, $1) }
//}
//
//func +<A>(_ lhs: @escaping (A) -> (), _ rhs: @escaping (A) -> ()) -> (A) -> () {
//    return { lhs($0); rhs($0) }
//}

extension PrimitiveSequenceType where Trait == SingleTrait {
    
    public func await() throws -> Element {
        var e: Element?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        var d: Disposable?
        DispatchQueue.global().async {
            d = self.primitiveSequence.asObservable().subscribe { (event) in
                switch event {
                case .next(let element):
                    e = element
                case .error(let error):
                    err = error; semaphore.signal()
                case .completed: semaphore.signal()
                }
            }
        }
        semaphore.wait()
        d?.dispose()
        if let er = err {
            throw er
        } else if e == nil {
            throw RxError.noElements
        }
        return e!
    }
    
}
