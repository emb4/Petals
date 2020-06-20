//
//  DetailView.swift
//  Petals SwiftUI
//
//  Created by Eric Bates on 6/14/20.
//  Copyright © 2020 Eric Bates. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    
    let url: URL?
    
    var body: some View {
        WebView(url: url)
            .edgesIgnoringSafeArea(.all)
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(url: URL(string: "https://en.wikipedia.org/wiki/Helianthus"))
    }
}
