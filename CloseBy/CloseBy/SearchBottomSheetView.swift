//
//  SearchBottomSheetView.swift
//  CloseBy
//
//  Created by Omer Oguz Celikel on 5.06.2025.
//

import SwiftUI
import MapKit
import Combine

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private var completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .pointOfInterest
    }
    
    func search(with query: String, in region: MKCoordinateRegion? = nil) {
        // Update the region to current map region
        if let region = region {
            completer.region = region
        }
        
        // Update the search query
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Publish the new results
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search suggestion error: \(error.localizedDescription)")
    }
}

struct SearchBottomSheetView: View {
    @ObservedObject var locationManager: LocationManager
    @StateObject var searchCompleter = SearchCompleter()
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .cornerRadius(2)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search in map", text: $searchText)
                    .focused($isTextFieldFocused)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .onSubmit {
                        performFullSearch(searchText)
                    }
                    .onChange(of: searchText) { newValue in
                        if !newValue.isEmpty {
                            // Update suggestions as user types
                            searchCompleter.search(with: newValue, in: locationManager.region)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Results and suggestions
            if isSearching {
                HStack {
                    ProgressView()
                        .padding(.trailing, 5)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !searchResults.isEmpty {
                // Search results
                List {
                    ForEach(searchResults, id: \.self) { item in
                        Button(action: {
                            selectSearchResult(item)
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown place")
                                        .font(.headline)
                                    
                                    Text(formatAddress(for: item.placemark))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            } else if !searchText.isEmpty && !searchCompleter.results.isEmpty {
                // Dynamic suggestions as user types - this will show immediately
                List {
                    ForEach(searchCompleter.results, id: \.self) { suggestion in
                        Button(action: {
                            performFullSearch(suggestion.title)
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(suggestion.title)
                                        .font(.headline)
                                    
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            } else if !searchText.isEmpty {
                // No results found
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No results found")
                        .font(.headline)
                    
                    Text("Try searching for a place or address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    // Recent searches
                    if !recentSearches.isEmpty {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Recent Searches")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Clear") {
                                    recentSearches = []
                                    UserDefaults.standard.removeObject(forKey: "recentSearches")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            ForEach(recentSearches.prefix(5), id: \.self) { search in
                                Button(action: {
                                    performFullSearch(search)
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .frame(width: 30)
                                        Text(search)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                    }
                    
                    // Suggestions when no search
                    VStack(alignment: .leading) {
                        Text("Search Suggestions")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, recentSearches.isEmpty ? 8 : 0)
                        
                        Button(action: {
                            performFullSearch("Restaurants")
                        }) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .frame(width: 30)
                                Text("Restaurants nearby")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            performFullSearch("Gas stations")
                        }) {
                            HStack {
                                Image(systemName: "fuelpump")
                                    .frame(width: 30)
                                Text("Gas stations")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            performFullSearch("Coffee")
                        }) {
                            HStack {
                                Image(systemName: "cup.and.saucer")
                                    .frame(width: 30)
                                Text("Coffee shops")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            performFullSearch("Hotels")
                        }) {
                            HStack {
                                Image(systemName: "bed.double")
                                    .frame(width: 30)
                                Text("Hotels")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            performFullSearch("Shopping")
                        }) {
                            HStack {
                                Image(systemName: "bag")
                                    .frame(width: 30)
                                Text("Shopping")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            // Focus the text field when the sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // Perform full search with results
    private func performFullSearch(_ query: String) {
        guard !query.isEmpty else { return }
        
        // Update the search text
        searchText = query
        
        // Add to recent searches
        if !recentSearches.contains(query) {
            recentSearches.insert(query, at: 0)
            if recentSearches.count > 10 {
                recentSearches = Array(recentSearches.prefix(10))
            }
            UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
        }
        
        isSearching = true
        searchResults = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = locationManager.region
        
        // Configure search for points of interest and addresses
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                guard error == nil, let response = response else {
                    print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.searchResults = response.mapItems
            }
        }
    }
    
    private func selectSearchResult(_ mapItem: MKMapItem) {
        // Create a coordinate and update the map
        let coordinate = mapItem.placemark.coordinate
        
        // Create place info
        let placeInfo = PlaceInfo(
            name: mapItem.name ?? "Selected Location",
            coordinate: coordinate,
            address: formatAddress(for: mapItem.placemark)
        )
        
        // Update location manager
        locationManager.setSelectedPlace(placeInfo)
        
        // Dismiss keyboard
        isTextFieldFocused = false
    }
    
    private func formatAddress(for placemark: MKPlacemark) -> String {
        let address = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
        
        return address.isEmpty ? "No address available" : address
    }
}
