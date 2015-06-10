<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Unbenanntes Dokument</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>

<body>

<?php
foreach (array_reverse(glob('./uploads/*.*')) as $filename) {
    //echo "$filename size " . filesize($filename) . "\n";
	echo "<img src='" . $filename . "' class='thumbnail' 
			onclick=\"window.top.window.getP5().loadPicture(this.src)\"/>\n";
}
?>
</body>
</html>