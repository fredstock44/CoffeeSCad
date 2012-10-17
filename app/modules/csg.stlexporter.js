// Generated by CoffeeScript 1.3.3
(function() {

  define(function(require) {
    var CsgStlExporter, csg, getBlobBuilder, getWindowURL, revokeBlobUrl, textToBlobUrl;
    csg = require('csg');
    getBlobBuilder = function() {
      bb;

      var bb;
      if (window.BlobBuilder) {
        bb = new window.BlobBuilder();
      } else if (window.WebKitBlobBuilder) {
        bb = new window.WebKitBlobBuilder();
      } else if (window.MozBlobBuilder) {
        bb = new window.MozBlobBuilder();
      } else {
        throw new Error("Your browser doesn't support BlobBuilder");
      }
      return bb;
    };
    getWindowURL = function() {
      if (window.URL) {
        return window.URL;
      } else if (window.webkitURL) {
        return window.webkitURL;
      } else {
        throw new Error("Your browser doesn't support window.URL");
      }
    };
    textToBlobUrl = function(txt) {
      var bb, blob, blobURL, windowURL;
      bb = getBlobBuilder();
      windowURL = getWindowURL();
      bb.append(txt);
      blob = bb.getBlob();
      blobURL = windowURL.createObjectURL(blob);
      if (!blobURL) {
        throw new Error("createObjectURL() failed");
      }
      return blobURL;
    };
    revokeBlobUrl = function(url) {
      if (window.URL) {
        return window.URL.revokeObjectURL(url);
      } else if (window.webkitURL) {
        return window.webkitURL.revokeObjectURL(url);
      } else {
        throw new Error("Your browser doesn't support window.URL");
      }
    };
    return CsgStlExporter = (function() {

      function CsgStlExporter() {
        this.hasOutputFile;
      }

      CsgStlExporter.prototype.clearOutputFile = function() {
        if (this.hasOutputFile) {
          this.hasOutputFile(false);
        }
        if (this.outputFileDirEntry) {
          this.outputFileDirEntry.removeRecursively(function() {
            return {};
          });
          this.outputFileDirEntry = null;
        }
        if (this.outputFileBlobUrl) {
          revokeBlobUrl(this.outputFileBlobUrl);
          this.outputFileBlobUrl = null;
        }
        return this.enableItems();
      };

      CsgStlExporter.prototype.generateOutputFile = function() {
        this.clearOutputFile();
        if (this.hasValidCurrentObject) {
          try {
            return this.generateOutputFileFileSystem();
          } catch (e) {
            return this.generateOutputFileBlobUrl();
          }
        }
      };

      CsgStlExporter.prototype.currentObjectToBlob = function() {
        var bb, blob, mimetype;
        bb = getBlobBuilder();
        mimetype = this.mimeTypeForCurrentObject();
        if (this.currentObject instanceof CSG) {
          this.currentObject.fixTJunctions().toStlBinary(bb);
          mimetype = "application/sla";
        } else if (this.currentObject instanceof CAG) {
          this.currentObject.toDxf(bb);
          mimetype = "application/dxf";
        } else {
          throw new Error("Not supported");
        }
        blob = bb.getBlob(mimetype);
        return blob;
      };

      CsgStlExporter.prototype.mimeTypeForCurrentObject = function() {
        var ext;
        return ext = this.extensionForCurrentObject();
      };

      CsgStlExporter.prototype.extensionForCurrentObject = function() {
        var extension;
        if (this.currentObject instanceof CSG) {
          extension = "stl";
        } else if (this.currentObject instanceof CAG) {
          extension = "dxf";
        } else {
          throw new Error("Not supported");
        }
        return extension;
      };

      CsgStlExporter.prototype.downloadLinkTextForCurrentObject = function() {
        var ext;
        ext = this.extensionForCurrentObject();
        return "Download " + ext.toUpperCase();
      };

      CsgStlExporter.prototype.generateOutputFileBlobUrl = function() {
        var blob, windowURL;
        blob = this.currentObjectToBlob();
        windowURL = getWindowURL();
        this.outputFileBlobUrl = windowURL.createObjectURL(blob);
        if (!this.outputFileBlobUrl) {
          throw new Error("createObjectURL() failed");
        }
        this.hasOutputFile = true;
        this.downloadOutputFileLink.href = this.outputFileBlobUrl;
        this.downloadOutputFileLink.innerHTML = this.downloadLinkTextForCurrentObject();
        return this.enableItems();
      };

      /*
          generateOutputFileFileSystem: ()-> 
            
            window.requestFileSystem  = window.requestFileSystem || window.webkitRequestFileSystem
            if(!window.requestFileSystem)
            {
              throw new Error("Your browser does not support the HTML5 FileSystem API. Please try the Chrome browser instead.")
            }
            // create a random directory name:
            dirname = "OpenJsCadOutput1_"+parseInt(Math.random()*1000000000, 10)+"."+extension
            extension = @extensionForCurrentObject()
            filename = @filename+"."+extension
            that = this
            window.requestFileSystem(TEMPORARY, 20*1024*1024, function(fs){
                fs.root.getDirectory(dirname, {create: true, exclusive: true}, function(dirEntry) {
                    that.outputFileDirEntry = dirEntry
                    dirEntry.getFile(filename, {create: true, exclusive: true}, function(fileEntry) {
                         fileEntry.createWriter(function(fileWriter) {
                            fileWriter.onwriteend = function(e) {
                              that.hasOutputFile = true
                              that.downloadOutputFileLink.href = fileEntry.toURL()
                              that.downloadOutputFileLink.type = that.mimeTypeForCurrentObject() 
                              that.downloadOutputFileLink.innerHTML = that.downloadLinkTextForCurrentObject()
                              that.enableItems()
                              if(that.onchange) that.onchange()
                            }
                            fileWriter.onerror = function(e) {
                              throw new Error('Write failed: ' + e.toString())
                            }
                            blob = that.currentObjectToBlob()
                            fileWriter.write(blob)                
                          }, 
                          function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "createWriter")} 
                        )
                      },
                      function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "getFile('"+filename+"')")} 
                    )
                  },
                  function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "getDirectory('"+dirname+"')")} 
                )         
              }, 
              function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "requestFileSystem")}
            )
      */


      return CsgStlExporter;

    })();
  });

}).call(this);
