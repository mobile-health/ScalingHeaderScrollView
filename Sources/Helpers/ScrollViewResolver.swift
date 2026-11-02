//
//  ScrollViewResolver.swift
//  ScalingHeaderScrollView
//
//  Created by Alisa Mylnikova on 13.07.2026.
//

import SwiftUI

struct ScrollViewResolver: UIViewRepresentable {
    var onResolve: (UIScrollView) -> Void

    func makeUIView(context: Context) -> ScrollViewResolverView {
        let view = ScrollViewResolverView()
        view.onResolve = onResolve
        return view
    }

    func updateUIView(_ uiView: ScrollViewResolverView, context: Context) {
        uiView.onResolve = onResolve
        uiView.resolveIfNeeded()
    }
}

/// SwiftUI rebuilds the hosting `UIScrollView` without calling `updateUIView`
/// again. Resolving only from `updateUIView` latches the first instance, which
/// then stays at offset 0 while the replacement scrolls the page and the header
/// never collapses. Re-resolve whenever this view joins a different scroll view.
final class ScrollViewResolverView: UIView {
    var onResolve: ((UIScrollView) -> Void)?
    private weak var resolved: UIScrollView?
    private var resolveScheduled = false

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        resolveIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        resolveIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let scrollView = enclosingScrollView(), scrollView !== resolved else { return }
        resolveIfNeeded()
    }

    func resolveIfNeeded() {
        guard !resolveScheduled else { return }
        resolveScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.resolveScheduled = false
            guard let scrollView = self.enclosingScrollView(), scrollView !== self.resolved else { return }
            self.resolved = scrollView
            self.onResolve?(scrollView)
        }
    }
}

extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var ancestor = superview
        while let current = ancestor {
            if let scroll = current as? UIScrollView {
                return scroll
            }
            ancestor = current.superview
        }
        // Fallback for .background placement where the resolver is a sibling of the scroll view
        return superview?.subviews.compactMap { $0 as? UIScrollView }.first
    }
}
