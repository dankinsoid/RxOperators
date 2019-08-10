//
//  ValueSubject.swift
//  RxOperators
//
//  Created by Daniil on 10.08.2019.
//

import RxSwift
import RxCocoa

public final class ValueSubject<Element>: DisposableObservableType, DisposableObserverType {
    
    public var value: Element {
        get { return lock.protect { _value } }
        set {
            lock.protect { _value = newValue }
            publishSubject.onNext(newValue)
        }
    }
    private let disposeBag = DisposeBag()
    private let lock = NSRecursiveLock()
    private var _value: Element
    private let publishSubject = PublishSubject<Element>()
    
    public init(_ value: Element) {
        _value = value
    }
    
    @discardableResult
    public func subscribe<O: ObserverType>(_ observer: O) -> Disposable where Element == O.Element {
        let result = publishSubject.subscribe(observer)
        insert(disposable: result)
        observer.onNext(value)
        return result
    }
    
    public func on(_ event: Event<Element>) {
        guard case .next(let newValue) = event else { return }
        value = newValue
    }
    
    public func insert(disposable: Disposable) {
        disposeBag.insert(disposable)
    }
    
}

extension ValueSubject: Decodable where Element: Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        try self.init(Element(from: decoder))
    }
    
}

extension ValueSubject: Encodable where Element: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
    
}
