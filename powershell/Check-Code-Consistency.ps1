$object_path_array = @(
      "C:\dev\project1\*.sql"
    , "C:\dev\project2\*.sql"
)

############################
# File name with no schema #
############################
Write-Host "`r`nThe file name should have the schema prefix:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.FullName | Select-String -Pattern "\Functions\", "\Stored Procedures\", "\Tables\", "\Views" -SimpleMatch -Quiet)
        {
            $object_name = $file.BaseName.split(".")[1] # Strip off the schema prefix

            if (!($object_name))
            {
                "$($file.Name)"
            }
        }
    }   
}

###########################
# File Name = Object Name #
###########################
Write-Host "`r`nThe file name (object name) should be found in the file:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {       
        $object_name = $file.BaseName.split(".")[1] # Strip off the schema prefix

        if (!($object_name))
        {
            "$($file.Name) - No schema prefix"
        }
        elseif (!(Select-String -Path $file.FullName -Pattern $object_name -SimpleMatch -Quiet))
        {
            "$($file.Name)"
        }
    }   
}

##########################
# No space in file names #
##########################
Write-Host "`r`nThe file name should not contain spaces:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.BaseName | Select-String -Pattern " " -SimpleMatch -Quiet)
        {
            "$($file.Name)"
        }
    }   
}

##########################
# Check table definition #
##########################
Write-Host "`r`nThe table definition should not contain keywords that could cause a table rebuild:"  -ForegroundColor Cyan

foreach ($object_path in $object_path_array)
{
    $files = Get-ChildItem $object_path -Recurse

    foreach ($file in $files)
    {
        if ($file.FullName | Select-String -Pattern "\Tables\" -SimpleMatch -Quiet)
        {
            # cast(     => convert()
            # between   => >= and <=
            # in (      => or
            # -1.9 * 3  => -(1.9 * 3)
            if (Select-String -Path $file.FullName -Pattern "cast\(", " between ", " in \(", "day\(", "as\s.+-\d" -Quiet)
            {
                "$($file.Name)"
            }
        }
    }   
}
