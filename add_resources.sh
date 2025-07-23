#!/bin/bash

# Add the JSON editor resources to the Xcode project
cd Tools

# Add the files to the project using xcodebuild
echo "Adding JSON editor resources to Xcode project..."

# We'll need to manually add these to the project file since we don't have xcodebuild add-file command
# For now, let's just copy them to the right location and they should be picked up

echo "Files are already in the correct location:"
echo "- Tools/Resources/jsonviewer.html"
echo "- Tools/Resources/jsoneditor.min.js" 
echo "- Tools/Resources/jsoneditor.min.css"

echo "Please add these files to the Xcode project manually by:"
echo "1. Opening Tools.xcodeproj in Xcode"
echo "2. Right-clicking on the Resources folder"
echo "3. Selecting 'Add Files to Tools'"
echo "4. Selecting the three files in Tools/Resources/"
echo "5. Making sure 'Add to target: Tools' is checked"