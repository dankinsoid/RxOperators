//
//  PublishDisposeSubject.swift
//  RxOperators
//
//  Created by Daniil on 10.08.2019.
//

import RxSwift
import RxCocoa

public final class PublishDisposeSubject<Element>: DisposableObservableType, DisposableObserverType {
    private let disposeBag = DisposeBag()
    private let publishSubject = PublishSubject<Element>()
    
    @discardableResult
    public func subscribe<O: ObserverType>(_ observer: O) -> Disposable where Element == O.Element {
        let result = publishSubject.subscribe(observer)
        insert(disposable: result)
        return result
    }
    
    public func on(_ event: Event<Element>) {
        publishSubject.on(event)
    }
    
    public func insert(disposable: Disposable) {
        disposeBag.insert(disposable)
    }
    
    public func asObservable() -> Observable<Element> {
        return publishSubject.asObservable()
    }
    
    public func asObserver() -> AnyObserver<Element> {
        return publishSubject.asObserver()
    }
    
}
