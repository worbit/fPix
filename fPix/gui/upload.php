<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Unbenanntes Dokument</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
<?php

$result = '';

if ($_FILES['fileToUpload']['error'] > 0) {
    //$result = "Error: " . $_FILES['fileToUpload']['error'] . "<br />";
} else {
    // array of valid extensions
    $validExtensions = array('.jpg', '.jpeg', '.gif', '.png', '.tga');
    // get extension of the uploaded file
    $fileExtension = strrchr($_FILES['fileToUpload']['name'], ".");
    // check if file Extension is on the list of allowed ones
    if (in_array($fileExtension, $validExtensions)) {
        // we are renaming the file so we can upload files with the same name
        // we simply put current timestamp in fron of the file name
        $newName = 'z' . time() . '_' . $_FILES['fileToUpload']['name'];
        $destination = 'uploads/' . $newName;
        if (@move_uploaded_file($_FILES['fileToUpload']['tmp_name'], $destination)) {
            //echo 'File ' .$newName. ' succesfully copied';
			/*echo "<img src='" . $destination . "' class='thumbnail' 
			onclick=\"window.top.window.getP5().loadPicture(this.src)\"/>\n";*/
			$result = $destination;
			
        }
    } else {
        //$result = 'You must upload an image...';
    }
}

//sleep(1);

foreach (array_reverse(glob('./uploads/*.*')) as $filename) {
    //echo "$filename size " . filesize($filename) . "\n";
	echo "<img src='" . $filename . "' class='thumbnail' 
			onclick=\"window.top.window.getP5().loadPicture(this.src)\"/>\n";
}

?>

<script language="javascript" type="text/javascript">
var jsresult = "<?php echo $result; ?>";
window.top.window.tryLoading(jsresult);
</script>
</body>
</html>