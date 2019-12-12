//
//  ValueSubject.swift
//  RxOperators
//
//  Created by Daniil on 10.08.2019.
//

import RxSwift
import RxCocoa

@propertyWrapper
public final class ValueSubject<Element>: DisposableObservableType, DisposableObserverType {
    
    public var wrappedValue: Element {
        get { value }
        set { value = newValue }
    }
    public var value: Element {
        get { return lock.protect { _value } }
        set {
            setValue(newValue)
            publishSubject.onNext(newValue)
        }
    }
    private let disposeBag = DisposeBag()
    private let lock = NSRecursiveLock()
    private var _value: Element
    private let publishSubject = PublishSubject<Element>()
    
    public init(wrappedValue initialValue: Element) {
        _value = initialValue
    }
    
    public convenience init(_ value: Element) {
        self.init(wrappedValue: value)
    }
    
    @discardableResult
    public func subscribe<O: ObserverType>(_ observer: O) -> Disposable where Element == O.Element {
        let result = publishSubject.subscribe(observer)
        insert(disposable: result)
        observer.onNext(value)
        return result
    }
    
    public func asNotSharing() -> AnyObserver<Element> {
        return AnyObserver {[weak self] in
            guard case .next(let newValue) = $0 else { return }
            self?.setValue(newValue)
        }
    }
    
    public func on(_ event: Event<Element>) {
        guard case .next(let newValue) = event else { return }
        value = newValue
    }
    
    public func insert(disposable: Disposable) {
        disposeBag.insert(disposable)
    }
    
    private func setValue(_ newValue: Element) {
        lock.protect { _value = newValue }
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
