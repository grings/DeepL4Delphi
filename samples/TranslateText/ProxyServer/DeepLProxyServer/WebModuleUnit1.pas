(* C2PP
  ***************************************************************************

  DeepL API client library for Delphi

  Copyright 2020-2025 Patrick Pr�martin under AGPL 3.0 license.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.

  ***************************************************************************

  DeepL is an online text and document translation tool, also available as
  software and APIs.

  This project is a client library in Pascal for Delphi to use the main
  translation API. Examples of use are also proposed.

  To use the API of DeepL you must have a free or paid account.

  ***************************************************************************

  Author(s) :
  Patrick PREMARTIN

  Site :
  https://deepl4delphi.developpeur-pascal.fr

  Project site :
  https://github.com/DeveloppeurPascal/DeepL4Delphi

  ***************************************************************************
  File last update : 2025-02-09T11:03:31.765+01:00
  Signature : 181d7867d261c0fa9def550f10b3d534a1830ea0
  ***************************************************************************
*)

unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp;

type
  TWebModule1 = class(TWebModule)
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModule1APITranslateAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;
  apikey: string;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

uses OlfSoftware.DeepL.ClientLib, System.json, System.Generics.Collections;

{$R *.dfm}

type
  TListeTraductions = TObjectDictionary<string, tjsonobject>;

var
  ListeTraductions: TListeTraductions;

procedure TWebModule1.WebModule1APITranslateAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  SourceLang, TargetLang, Texte, SplitSentences, PreserveFormatting,
    Formality: string;
  LTK: string;
  TexteTraduit: string;
  jso: tjsonobject;
begin
  // writeln(request.Content);

  // for var i := 0 to request.ContentFields.Count-1 do
  // writeln(          request.ContentFields[i]);

  Response.CustomHeaders.Add('Access-Control-Allow-Origin=*');

  // r�cup�rer les param�tres de la requ�te
  if (Request.ContentFields.IndexOfName('source_lang') < 0) then
  begin
    Response.StatusCode := 404;
    exit;
  end
  else
    SourceLang := Request.ContentFields.Values['source_lang'];
  if (Request.ContentFields.IndexOfName('target_lang') < 0) then
  begin
    Response.StatusCode := 404;
    exit;
  end
  else
    TargetLang := Request.ContentFields.Values['target_lang'];
  if (Request.ContentFields.IndexOfName('text') < 0) then
  begin
    Response.StatusCode := 404;
    exit;
  end
  else
    Texte := Request.ContentFields.Values['text'];
  if (Request.ContentFields.IndexOfName('split_sentences') < 0) then
    SplitSentences := '1'
  else
    SplitSentences := Request.ContentFields.Values['split_sentences'];
  if (Request.ContentFields.IndexOfName('preserve_formatting') < 0) then
    PreserveFormatting := '0'
  else
    PreserveFormatting := Request.ContentFields.Values['preserve_formatting'];
  if (Request.ContentFields.IndexOfName('formality') < 0) then
    Formality := 'default'
  else
    Formality := Request.ContentFields.Values['formality'];
  // regarder si on a d�j� fait cette demande
  LTK := SourceLang + TargetLang + Texte + SplitSentences + PreserveFormatting +
    Formality;
  // si oui, envoyer la r�ponse de d�part
  if ListeTraductions.ContainsKey(LTK) then
  begin
    Response.StatusCode := 200;
    Response.ContentType := 'application/json';
    // Response.CustomHeaders.Add('Access-Control-Allow-Origin=*');
    Response.Content := ListeTraductions[LTK].tojson;
  end
  else
  begin
    // si non, faire la demande � DeepL et stocker la r�ponse
    try
      TexteTraduit := DeepLTranslateTextSync(apikey, SourceLang, TargetLang,
        Texte, SplitSentences, PreserveFormatting, Formality);
      // retourner la r�ponse trouv�e dans le cache ou provanent de DeepL
      Response.StatusCode := 200;
      Response.ContentType := 'application/json';
      // Response.CustomHeaders.Add('Access-Control-Allow-Origin=*');
      jso := tjsonobject.create;
      try
        jso.AddPair('translations',
          tjsonarray.create.Add(tjsonobject.create.AddPair
          ('detected_source_language', TargetLang).AddPair('text',
          TexteTraduit)));
        MonitorEnter(ListeTraductions);
        try
          ListeTraductions.Add(LTK, jso);
        finally
          MonitorExit(ListeTraductions);
        end;
        Response.Content := jso.tojson;
      finally
        // jso.free;
        // attached to the ListeTraductions dictionary,
        // using Free will generate access violations when accessing to jso values
      end;
    except
      Response.StatusCode := 500;
    end;
  end;
end;

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content := '<html>' + '<head><title>Proxy DeepL</title></head>' +
    '<body>Proxy DeepL is waiting for your messages.</body>' + '</html>';
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}
apikey := '';
ListeTraductions := TListeTraductions.create;

finalization

ListeTraductions.free;

end.
