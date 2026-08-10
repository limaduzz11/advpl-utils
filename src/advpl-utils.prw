#include "protheus.ch"

/*--------------------------------------------------------------------*
| ADVPL Utils — Funcoes utilitarias genericas para TOTVS Protheus
| Autor: Eduardo Paranhos
| Data:  10/08/2026
| Obs.:  Exemplos genericos — sem dados proprietarios
*---------------------------------------------------------------------*/

/*--------------------------------------------------------------------*
| StrFormat — Formata string com mascara (CPF, CNPJ, CEP, telefone)
*---------------------------------------------------------------------*/
User Function StrFormat(cValue, cType)

    Local cResult := ""
    Default cType := ""

    cValue := AllTrim(cValue)
    cValue := StrTran(cValue, ".", "")
    cValue := StrTran(cValue, "-", "")
    cValue := StrTran(cValue, "/", "")
    cValue := StrTran(cValue, "(", "")
    cValue := StrTran(cValue, ")", "")
    cValue := StrTran(cValue, " ", "")

    Do Case
    Case cType == "CPF" .And. Len(cValue) == 11
        cResult := SubStr(cValue, 1, 3) + "." + SubStr(cValue, 4, 3) + "." + ;
                   SubStr(cValue, 7, 3) + "-" + SubStr(cValue, 10, 2)

    Case cType == "CNPJ" .And. Len(cValue) == 14
        cResult := SubStr(cValue, 1, 2) + "." + SubStr(cValue, 3, 3) + "." + ;
                   SubStr(cValue, 6, 3) + "/" + SubStr(cValue, 9, 4) + "-" + SubStr(cValue, 13, 2)

    Case cType == "CEP" .And. Len(cValue) == 8
        cResult := SubStr(cValue, 1, 5) + "-" + SubStr(cValue, 6, 3)

    Case cType == "FONE" .And. Len(cValue) >= 10
        cResult := "(" + SubStr(cValue, 1, 2) + ") " + SubStr(cValue, 3, Len(cValue) - 2)

    Otherwise
        cResult := cValue
    EndCase

Return cResult

/*--------------------------------------------------------------------*
| BusinessDays — Retorna dias uteis entre duas datas
*---------------------------------------------------------------------*/
User Function BusinessDays(dStart, dEnd)

    Local nDays := 0
    Local dDate := dStart

    Default dEnd := Date()

    While dDate <= dEnd
        If Dow(dDate) != 1 .And. Dow(dDate) != 7 // Nao e domingo (1) nem sabado (7)
            nDays++
        EndIf
        dDate := DaySum(dDate, 1)
    EndDo

Return nDays

/*--------------------------------------------------------------------*
| AddMonth — Soma/subtrai meses de uma data
*---------------------------------------------------------------------*/
User Function AddMonth(dDate, nMonths)

    Local nDay := Day(dDate)
    Local nMonth := Month(dDate) + nMonths
    Local nYear := Year(dDate)
    Local dResult

    // Ajusta ano
    While nMonth > 12
        nMonth -= 12
        nYear++
    EndDo
    While nMonth < 1
        nMonth += 12
        nYear--
    EndDo

    // Ajusta ultimo dia do mes
    dResult := StoD(StrZero(nDay, 2) + StrZero(nMonth, 2) + StrZero(nYear, 4))

Return dResult

/*--------------------------------------------------------------------*
| ExportToCSV — Exporta consulta SQL para arquivo CSV
*---------------------------------------------------------------------*/
User Function ExportToCSV(cQuery, cFile)

    Local cLine := ""
    Local nHandle := 0
    Local aRow := {}

    Default cFile := "/tmp/export_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + ".csv"

    // Abre arquivo
    nHandle := fCreate(cFile)
    If nHandle == -1
        MsgAlert("Erro ao criar arquivo: " + cFile, "Export CSV")
        Return .F.
    EndIf

    // Executa query
    DbUseArea(.T., "TOPCONN", TCGenQry(Nil, Nil, cQuery), "TMPQRY", .F., .T.)

    // Escreve cabecalho
    cLine := ""
    For nI := 1 To FCount()
        cLine += FieldName(nI) + ";"
    Next nI
    fWrite(nHandle, cLine + Chr(13) + Chr(10))

    // Escreve dados
    DbGoTop()
    While !Eof()
        cLine := ""
        For nI := 1 To FCount()
            cLine += cValToChar(FieldGet(nI)) + ";"
        Next nI
        fWrite(nHandle, cLine + Chr(13) + Chr(10))
        DbSkip()
    EndDo

    fClose(nHandle)
    TMPQRY->(DbCloseArea())

    ConOut("[ExportCSV] Arquivo gerado: " + cFile)

Return .T.

/*--------------------------------------------------------------------*
| SafeExec — Try-catch padrao para ADVPL
*---------------------------------------------------------------------*/
User Function SafeExec(bBlock, cErrorMsg)

    Local xResult := Nil
    Local bError := ErrorBlock({|e| Break(e)})

    Default cErrorMsg := "Erro na execucao"

    Begin Sequence
        xResult := Eval(bBlock)
    Recover Using oError
        ConOut("[SafeExec] " + cErrorMsg + ": " + oError:Description)
        xResult := Nil
    End Sequence

    ErrorBlock(bError) // Restaura handler original

Return xResult

/*--------------------------------------------------------------------*
| IsValidEmail — Valida formato de email
*---------------------------------------------------------------------*/
User Function IsValidEmail(cEmail)

    Local lValid := .F.

    If !Empty(cEmail) .And. "@" $ cEmail .And. "." $ SubStr(cEmail, At("@", cEmail) + 1)
        lValid := .T.
    EndIf

Return lValid

/*--------------------------------------------------------------------*
| AgeInDays — Calcula idade em dias de uma data
*---------------------------------------------------------------------*/
User Function AgeInDays(dDate)
Return Date() - dDate

/*--------------------------------------------------------------------*
| PercentOf — Calcula percentual de um valor sobre outro
*---------------------------------------------------------------------*/
User Function PercentOf(nPart, nTotal)
    If nTotal == 0
        Return 0
    EndIf
Return (nPart / nTotal) * 100

/*--------------------------------------------------------------------*
| ArrayContains — Verifica se array contem valor
*---------------------------------------------------------------------*/
User Function ArrayContains(aArray, xValue)
    Return (aScan(aArray, {|x| x == xValue}) > 0)
