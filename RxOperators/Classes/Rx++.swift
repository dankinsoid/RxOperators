//
//  Rx++.swift
//  MusicImport
//
//  Created by Данил Войдилов on 21.06.2019.
//  Copyright © 2019 Данил Войдилов. All rights reserved.
//

import RxSwift
import RxCocoa
import UnwrapOperator

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
	
	func skipNil() -> Observable<Element.Wrapped> {
		return map({ $0.asOptional() }).filter({ $0 != nil }).map({ $0! })
	}
	
}

extension ObservableType where Element == String? {
	
	func orEmpty() -> Observable<String> {
		return map({ $0 ?? "" })
	}
	
}

extension ObservableType where Element == Bool? {
	
	func or(_ value: Bool) -> Observable<Bool> {
		return map({ $0 ?? value })
	}
	
}

extension ObservableType where Element == Bool {
	
	func toggle() -> Observable<Bool> {
		return map({ !$0 })
	}
	
}

extension ObservableType {
	
	func compactMap<U>(_ block: @escaping (Element) throws -> U?) -> Observable<U> {
		return map(block).skipNil()
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

struct WeakRef<T: AnyObject, Element>: ObserverType {
    weak var object: T?
    let keyPath: ReferenceWritableKeyPath<T, Element>
    
    func on(_ event: Event<Element>) {
        if case .next(let value) = event {
            object?[keyPath: keyPath] = value
        }
    }
    
}

struct WeakMethod<T: AnyObject, Element>: ObserverType {
    weak var object: T?
    let method: (T) -> (Element) -> ()
    
    func on(_ event: Event<Element>) {
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
    
}
