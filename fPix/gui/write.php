<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Unbenanntes Dokument</title>

<?php
		$data = $_POST["data"];
		$filename = "output/".$_POST["fn"];
		$handle = fopen("$filename.ncc", "w");
		fwrite($handle, $data);
		fclose($handle);

		
		header('Content-Type: application/octet-stream');
		header('Content-Disposition: attachment; filename='.basename("$filename.ncc"));
		header('Expires: 0');
		header('Cache-Control: must-revalidate');
		header('Pragma: public');
		header('Content-Length: ' . filesize("$filename.ncc"));
		readfile("$filename.ncc");
		exit;
		
?>

</head>

<body>
</body>
</html>