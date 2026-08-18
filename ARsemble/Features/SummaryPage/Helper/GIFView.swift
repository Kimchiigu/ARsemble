//
//  GIFView.swift
//  ARsemble
//
//  Created by Reynard Amadeus  on 18/08/26.
//
import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()

        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(
            forResource: gifName,
            withExtension: "GIF"
        ) else {
            print("❌ GIF not found: \(gifName).gif")
            return
        }

        webView.loadFileURL(
            url,
            allowingReadAccessTo: url.deletingLastPathComponent()
        )
    }
}
