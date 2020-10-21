//
//  DisposableObserver.swift
//  RxOperators
//
//  Created by Daniil on 10.08.2019.
//

import RxSwift
import RxCocoa

public protocol DisposableObserverType: class {
    associatedtype Element
    func on(_ event: Event<Element>)
    func observe<O: ObservableConvertibleType>(observable: O) where O.Element == Element
    func asObserver() -> AnyObserver<Element>
    func insert(disposable: Disposable)
}

extension DisposableObserverType {
    
    public func observe<O: ObservableConvertibleType>(_ observable: O) where O.Element == Element {
        insert(disposable: observable.asObservable().subscribe(asObserver()))
    }
    
    @discardableResult
    func observe<O: ObservableConvertibleType>(_ observable: O) -> Disposable where O.Element == Element {
        let result = observable.asObservable().subscribe(asObserver())
        insert(disposable: result)
        return result
    }
    
    public func observe<O: ObservableConvertibleType>(observable: O) where Element == O.Element {
        insert(disposable: observable.asObservable().subscribe(asObserver()))
    }
    
}

extension DisposableObserverType {
    
    public func asObserver() -> AnyObserver<Element> {
        return AnyObserver {[weak self] event in
            self?.on(event)
        }
    }
    
}

extension ObserverType where Self: AnyObject {
    
    public func asWeakObserver() -> AnyObserver<Element> {
        return AnyObserver {[weak self] event in
            self?.on(event)
        }
    }
    
}

public protocol DisposableObservableType: class, ObservableType {
    func insert(disposable: Disposable)
    func subscribe<O: ObserverType>(observer: O) where O.Element == Element
}

extension DisposableObservableType {
    
    public func subscribe<O: ObserverType>(observer: O) where O.Element == Element {
        let disposable = subscribe(observer)
        insert(disposable: disposable)
    }
    
    public func bind<O: ObserverType>(to observer: O) where O.Element == Element {
        let disposable = asObservable().subscribe(observer)
        insert(disposable: disposable)
    }
    
    public func bind<O: ObserverType>(to observer: O) where O.Element == Element? {
        let disposable = asObservable().map({ $0 as Element? }).subscribe(observer)
        insert(disposable: disposable)
    }
    
    public func asObservable() -> Observable<Element> {
        return Observable.create {[weak self] observer -> Disposable in
            if let disposable = self?.subscribe(observer) {
                self?.insert(disposable: disposable)
                return disposable
            }
            return Disposables.create()
        }
    }
    
}

public typealias DisposableSubjectType = DisposableObserverType & DisposableObservableType
