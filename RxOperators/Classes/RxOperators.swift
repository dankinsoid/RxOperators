//
//  RxOperators.swift
//
//  Created by Данил Войдилов on 19.07.2018.
//

import Foundation
import RxSwift
import RxCocoa

precedencegroup RxPrecedence {
	associativity: left
	higherThan: FunctionArrowPrecedence
}

infix operator <=> : RxPrecedence
infix operator <==> : RxPrecedence
infix operator => : RxPrecedence
infix operator ==> : RxPrecedence

public func =><T: ObservableType, O: AnyObject, E>(_ lhs: T?, _ rhs:  (O, (O) -> (E) -> ())) -> Disposable where E == T.Element {
    let deallocated = Reactive(rhs.0).deallocated
    return lhs?.takeUntil(deallocated).subscribe(Reactive(rhs.0).weak(method: rhs.1)) ?? Disposables.create()
}

public func =><O: ObservableType>(_ lhs: O?, _ rhs: @escaping (O.Element) -> ()) -> Disposable {
    return lhs?.asObservable().subscribe(onNext: rhs) ?? Disposables.create()
}

public func =><O: ObservableType>(_ lhs: O?, _ rhs: [(O.Element) -> ()]) -> Disposable {
	return lhs?.asObservable().subscribe(onNext: { next in rhs.forEach{ $0(next) } }) ?? Disposables.create()
}

public func =><T: ObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	return lhs?.asObservable().subscribe(rhs.asObserver()) ?? Disposables.create()
}

public func =><T: ObservableType, O: AnyObject, E>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, E>)) -> Disposable where E == T.Element {
	let deallocated = Reactive(rhs.0).deallocated
	return lhs?.takeUntil(deallocated).subscribe(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) ?? Disposables.create()
}

@discardableResult
public func =><T: DisposableObservableType, O: AnyObject, E>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, E>)) -> Disposable where E == T.Element {
	let deallocated = Reactive(rhs.0).deallocated
	if let result = lhs?.takeUntil(deallocated).subscribe(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

@discardableResult
public func =><O: DisposableObservableType>(_ lhs: O?, _ rhs: @escaping (O.Element) -> ()) -> Disposable {
	if let result = lhs?.asObservable().subscribe(onNext: rhs) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

@discardableResult
public func =><O: DisposableObservableType>(_ lhs: O?, _ rhs: [(O.Element) -> ()]) -> Disposable {
	if let result = lhs?.asObservable().subscribe(onNext: { next in rhs.forEach{ $0(next) } }) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

@discardableResult
public func =><T: ObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	let result = lhs?.asObservable().subscribe(rhs.asObserver()) ?? Disposables.create()
	rhs.insert(disposable: result)
	return result
}

@discardableResult
public func =><T: DisposableObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	if let result = lhs?.asObservable().subscribe(rhs.asObserver()) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

@discardableResult
public func =><T: DisposableObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	let result = lhs?.asObservable().subscribe(rhs.asObserver()) ?? Disposables.create()
	rhs.insert(disposable: result)
	lhs?.insert(disposable: result)
	return result
}

public func =>(_ lhs: Disposable?, _ rhs: DisposeBag) {
	lhs?.disposed(by: rhs)
}

public func =>(_ lhs: Disposable?, _ rhs: inout Disposable?) {
	rhs = lhs
}

public func =><T: ObservableType, O: SchedulerType>(_ lhs: T?, _ rhs: O) -> Observable<T.Element>? {
	return lhs?.observeOn(rhs)
}

public func ==><O: ObservableType>(_ lhs: O?, _ rhs: @escaping (O.Element) -> ()) -> Disposable {
	return lhs?.asDriver().drive(onNext: rhs) ?? Disposables.create()
}

@discardableResult
public func ==><O: DisposableObservableType>(_ lhs: O?, _ rhs: @escaping (O.Element) -> ()) -> Disposable {
	if let result = lhs?.asDriver().drive(onNext: rhs) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

public func ==><T: ObservableType, O: AnyObject, E>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, E>)) -> Disposable where E == T.Element {
	let deallocated = Reactive(rhs.0).deallocated
	return lhs?.takeUntil(deallocated).asDriver().drive(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) ?? Disposables.create()
}

public func ==><T: ObservableType, O: AnyObject, E>(_ lhs: T?, _ rhs:  (O, (O) -> (E) -> ())) -> Disposable where E == T.Element {
    let deallocated = Reactive(rhs.0).deallocated
    return lhs?.takeUntil(deallocated).asDriver().drive(Reactive(rhs.0).weak(method: rhs.1)) ?? Disposables.create()
}

@discardableResult
public func ==><T: DisposableObservableType, O: AnyObject, E>(_ lhs: T?, _ rhs: (O, ReferenceWritableKeyPath<O, E>)) -> Disposable where E == T.Element {
	let deallocated = Reactive(rhs.0).deallocated
	if let result = lhs?.takeUntil(deallocated).asDriver().drive(WeakRef(object: rhs.0, keyPath: rhs.1).asObserver()) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

public func ==><T: ObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	return lhs?.asDriver().drive(rhs) ?? Disposables.create()
}

@discardableResult
public func ==><T: DisposableObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	if let result = lhs?.asDriver().drive(rhs) {
		lhs?.insert(disposable: result)
		return result
	}
	return Disposables.create()
}

@discardableResult
public func ==><T: ObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	let result = lhs?.asObservable().asDriver().drive(rhs.asObserver()) ?? Disposables.create()
	rhs.insert(disposable: result)
	return result
}

@discardableResult
public func ==><T: DisposableObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == T.Element {
	let result = lhs?.asObservable().asDriver().drive(rhs.asObserver()) ?? Disposables.create()
	rhs.insert(disposable: result)
	lhs?.insert(disposable: result)
	return result
}

public func ==><T: ObservableType, O: ObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
	return lhs?.map({ $0 }).asDriver().drive(rhs) ?? Disposables.create()
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
public func ==><T: ObservableType, O: DisposableObserverType>(_ lhs: T?, _ rhs: O) -> Disposable where O.Element == Optional<T.Element> {
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

fileprivate func bind<Element: Equatable>(_ lO: Observable<Element>, _ rO: Observable<Element>, _ lOb: AnyObserver<Element>, _ rOb: AnyObserver<Element>) -> Disposable {
	let subject = PublishSubject<Element>()
	let d1 = lO.subscribe(subject)
	let d2 = rO.subscribe(subject)
	let d3 = subject.distinctUntilChanged().subscribe(rOb)
	let d4 = subject.distinctUntilChanged().subscribe(lOb)
	return Disposables.create(d1, d2, d3, d4)
}

public func <=><T: ObservableType & ObserverType, O: ObservableType & ObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	return bind(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
}

@discardableResult
public func <=><T: ObservableType & DisposableObserverType, O: ObservableType & ObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	let result = bind(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
	l.insert(disposable: result)
	return result
}

@discardableResult
public func <=><T: ObservableType & ObserverType, O: ObservableType & DisposableObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	let result = bind(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
	r.insert(disposable: result)
	return result
}

@discardableResult
public func <=><T: ObservableType & DisposableObserverType, O: ObservableType & DisposableObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	let result = bind(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
	r.insert(disposable: result)
	l.insert(disposable: result)
	return result
}

fileprivate func drive<Element: Equatable>(_ lO: Observable<Element>, _ rO: Observable<Element>, _ lOb: AnyObserver<Element>, _ rOb: AnyObserver<Element>) -> Disposable {
	let subject = PublishSubject<Element>()
	let d1 = lO.subscribe(subject)
	let d2 = rO.subscribe(subject)
	let d3 = subject.distinctUntilChanged().asDriver().drive(rOb)
	let d4 = subject.distinctUntilChanged().asDriver().drive(lOb)
	return Disposables.create(d1, d2, d3, d4)
}

public func <==><T: ObservableType & ObserverType, O: ObservableType & ObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	return drive(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
}

@discardableResult
public func <==><T: ObservableType & DisposableObserverType, O: ObservableType & ObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	let result = drive(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
	l.insert(disposable: result)
	return result
}

@discardableResult
public func <==><T: ObservableType & ObserverType, O: ObservableType & DisposableObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	let result = drive(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
	r.insert(disposable: result)
	return result
}

@discardableResult
public func <==><T: ObservableType & DisposableObserverType, O: ObservableType & DisposableObserverType>(_ lhs: T?, _ rhs: O?) -> Disposable where O.Element == T.Element, T.Element: Equatable {
	guard let l = lhs, let r = rhs else { return Disposables.create() }
	let result = drive(l.asObservable(), r.asObservable(), l.asObserver(), r.asObserver())
	r.insert(disposable: result)
	l.insert(disposable: result)
	return result
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
