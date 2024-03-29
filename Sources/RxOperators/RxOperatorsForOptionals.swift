//
//  RxOperatorsForOptionals.swift
//  RxOperators
//
//  Created by Daniil on 16.08.2019.
//

import RxSwift
import RxCocoa

public func =><T: ObservableConvertibleType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    return lhs?.asObservable().map({ $0 }).subscribe(rhs.asObserver()) ?? Disposables.create()
}

public func =><T: ObservableConvertibleType, O: AnyObject>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, T.Element?>)) -> Disposable {
    let deallocated = Reactive(rhs.0).deallocated
	return lhs?.asObservable().take(until: deallocated).map({ $0 }).subscribe(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) ?? Disposables.create()
}

@discardableResult
public func =><T: DisposableObservableType, O: AnyObject>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, T.Element?>)) -> Disposable {
    let deallocated = Reactive(rhs.0).deallocated
	if let result = lhs?.take(until: deallocated).map({ $0 }).subscribe(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) {
        lhs?.insert(disposable: result)
        return result
    }
    return Disposables.create()
}

@discardableResult
public func =><T: ObservableConvertibleType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    let result = lhs?.asObservable().map({ $0 }).subscribe(rhs.asObserver()) ?? Disposables.create()
    rhs.insert(disposable: result)
    return result
}

@discardableResult
public func =><T: DisposableObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    if let result = lhs?.map({ $0 }).subscribe(rhs.asObserver()) {
        lhs?.insert(disposable: result)
        return result
    }
    return Disposables.create()
}

@discardableResult
public func =><T: DisposableObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    let result = lhs?.map({ $0 }).subscribe(rhs.asObserver()) ?? Disposables.create()
    rhs.insert(disposable: result)
    lhs?.insert(disposable: result)
    return result
}

public func ==><T: ObservableConvertibleType, O: AnyObject>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, T.Element?>)) -> Disposable {
    let deallocated = Reactive(rhs.0).deallocated
	return lhs?.asObservable().take(until: deallocated).asDriver().drive(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) ?? Disposables.create()
}

@discardableResult
public func ==><T: DisposableObservableType, O: AnyObject>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, T.Element?>)) -> Disposable {
    let deallocated = Reactive(rhs.0).deallocated
	if let result = lhs?.take(until: deallocated).asDriver().drive(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) {
        lhs?.insert(disposable: result)
        return result
    }
    return Disposables.create()
}

public func ==><T: ObservableConvertibleType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    return lhs?.asObservable().map({ $0 }).asDriver().drive(rhs) ?? Disposables.create()
}

@discardableResult
public func ==><T: DisposableObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    if let result = lhs?.asObservable().map({ $0 }).asDriver().drive(rhs) {
        lhs?.insert(disposable: result)
        return result
    }
    return Disposables.create()
}

@discardableResult
public func ==><T: ObservableConvertibleType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    let result = lhs?.asObservable().map({ $0 }).asDriver().drive(rhs.asObserver()) ?? Disposables.create()
    rhs.insert(disposable: result)
    return result
}

@discardableResult
public func ==><T: DisposableObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
    let result = lhs?.asObservable().map({ $0 }).asDriver().drive(rhs.asObserver()) ?? Disposables.create()
    rhs.insert(disposable: result)
    lhs?.insert(disposable: result)
    return result
}

public func =>><A: ObservableConvertibleType, O: ObserverType>(_ lhs: A, _ rhs: O?) -> Disposable where O.Element: Equatable, O.Element == A.Element {
	guard let rhs = rhs else { return Disposables.create() }
	return lhs.asObservable().distinctUntilChanged() => rhs
}

public func =>><A: ObservableConvertibleType, O: ObserverType>(_ lhs: A, _ rhs: O?) -> Disposable where A.Element: Equatable, O.Element == A.Element? {
	guard let rhs = rhs else { return Disposables.create() }
	return lhs.asObservable().distinctUntilChanged() => rhs
}
