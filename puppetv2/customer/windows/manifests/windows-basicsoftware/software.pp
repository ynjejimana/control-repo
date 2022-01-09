class windows::windows-basicsoftware::software ($software) {
      create_resources (windows::windows-basicsoftware::packages, $software)
}

