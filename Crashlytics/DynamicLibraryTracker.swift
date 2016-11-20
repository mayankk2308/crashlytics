//
//  DynamicLibraryTracker.swift
//  Crashlytics
//
//  Created by Mayank Kumar on 11/8/16.
//  Copyright © 2016 Mayank Kumar. All rights reserved.
//

import Foundation
import CoreData

class DynamicLibraryTracker {
    
    // MARK: - UNIVERSAL PROPERTIES
    
    private static let context = DataManager.persistentContainer.viewContext
    private static var libraryLoadIndex = 0
    static var loadedLibraryCount = 0
    
    // MARK: - PRIMARY USER-SDK INTERACTION
    
    /*
     * Initialize the SDK and begin tracking.
     */
    
    static func initializeTracker() {
        _dyld_register_func_for_add_image(registerLibraryLoad)
    }
    
    /*
     * Output previously loaded libraries and clear the context.
     */
    
    static func outputPreviouslyLoadedLibraries() {
        let allData = fetchPreviouslyLoadedLibraries().sorted(by: <)
        loadedLibraryCount = allData.count
        if allData.count > 0 { print("\t\t-----BINARY IMAGES LOADED IN PREVIOUS RUN (\(loadedLibraryCount))-----\n\n") }
        for data in allData { print(data.0, data.1, data.2, data.3, "\n") }
    }
    
    // MARK: - PRIVATE SDK BACKBONE
    
    /*
     * The registerLibraryLoad function is C-convention-based Swift function that is called each time
     * a binary image is loaded.
     *
     * For every dynamic library, its name, base address, complete path, and load index is retrieved
     * and sent to another private function to persist the data.
     */
    
    private static let registerLibraryLoad: @convention(c) (UnsafePointer<mach_header>?, Int) -> Void = { pointer, address in
        var imageInfoPointer = UnsafeMutablePointer<Dl_info>.allocate(capacity: 1)
        let result = dladdr(pointer!, imageInfoPointer)
        if result == 0 {
            print("Unable to retrieve information from mach header.")
            return
        }
        let imageInfo: Dl_info = imageInfoPointer.pointee
        guard var imageNamePtr = imageInfo.dli_fname else {
            print("Unable to retrieve name of dynamic library.")
            return
        }
        guard let imageBaseAddress = imageInfo.dli_fbase else {
            print("Unable to retrieve base address of dynamic library.")
            return
        }
        let imagePath = String(cString: imageNamePtr)
        let imageName = imagePath.components(separatedBy: "/").last!
        let baseAddress = "\(imageBaseAddress) + \(address)"
        persistLibrary(withLoadIndex: libraryLoadIndex, withBaseAddress: baseAddress, withImageName: imageName, withImagePath: imagePath)
        libraryLoadIndex += 1
    }
    
    /*
     * The persistLibrary function takes binary image data -> load index, image base address, image name, and
     * image path and saves the entity. This happens for every loaded dynamic library over a single application.
     *
     * Note: Library data is truly persisted only when the application terminates/crashes. While in its life cycle,
     * the SDK keeps track of all dynamic libraries that are loaded and appends them to the context to be
     * persisted later.
     */
    
    private static func persistLibrary(withLoadIndex index: Int, withBaseAddress address: String, withImageName imageName: String, withImagePath imagePath: String) {
        let entity = NSEntityDescription.entity(forEntityName: "LibraryObject", in: context)
        let object = NSManagedObject(entity: entity!, insertInto: context)
        object.setValue(index, forKey: "loadIndex")
        object.setValue(address, forKey: "baseAddress")
        object.setValue(imageName, forKey: "libraryName")
        object.setValue(imagePath, forKey: "libraryPath")
    }
    
    /*
     * The fetchPreviouslyLoadedLibraries function retrieves a list of all dynamic libraries that were loaded in the
     * application's previous life cycle.
     *
     * Once all the data for the previous library is retrieved, that data is removed from the context and
     * new data for the current lifecycle is then stored.
     */
    
    private static func fetchPreviouslyLoadedLibraries() -> [(Int, String, String, String)] {
        var libraryData = [(Int, String, String, String)]()
        let fetchRequest: NSFetchRequest<LibraryObject> = LibraryObject.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            for result in results as [LibraryObject] {
                libraryData.append((Int(result.loadIndex), result.baseAddress!, result.libraryName!, result.libraryPath!))
                context.delete(result)
            }
        }
        catch { print("Unable to retrieve log.") }
        return libraryData
    }
    
}
