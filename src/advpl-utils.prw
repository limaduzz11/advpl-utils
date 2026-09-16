#include "protheus.ch"
#include "topconn.ch"

/*--------------------------------------------------------------------*
| ADVPL Utils — Funcoes utilitarias canônicas para TOTVS Protheus
| Autor: Eduardo Paranhos
| Data:  10/08/2026
| Obs.:  Rotinas reutilizaveis sem dependencias proprietarias
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
| BusinessDays — Retorna dias uteis considerando feriados do Protheus
*---------------------------------------------------------------------*/
User Function BusinessDays(dStart, dEnd)

    Local nDays := 0
    Local dDate := dStart

    Default dEnd := Date()

    While dDate <= dEnd
        // Verifica sabado (7), domingo (1) e tabela de feriados Protheus (DataValida)
        If Dow(dDate) != 1 .And. Dow(dDate) != 7 .And. DataValida(dDate, .T.) == dDate
            nDays++
        EndIf
        dDate := DaySum(dDate, 1)
    EndDo

Return nDays

/*--------------------------------------------------------------------*
| AddMonth — Soma/subtrai meses com clamp correto do ultimo dia
*---------------------------------------------------------------------*/
User Function AddMonth(dDate, nMonths)

    Local nDay     := Day(dDate)
    Local nMonth   := Month(dDate) + nMonths
    Local nYear    := Year(dDate)
    Local dFirstDay
    Local dLastDay
    Local nMaxDay  := 31
    Local dResult

    Default nMonths := 0

    // Ajusta viradas de ano
    While nMonth > 12
        nMonth -= 12
        nYear++
    EndDo
    While nMonth < 1
        nMonth += 12
        nYear--
    EndDo

    // Calcula ultimo dia valido para o mes/ano de destino (ex: 28/29 fev, 30 abr)
    dFirstDay := StoD(StrZero(nYear, 4) + StrZero(nMonth, 2) + "01")
    dLastDay  := LastDay(dFirstDay)
    nMaxDay   := Day(dLastDay)

    // Clamp para evitar datas invalidas (ex: 31 de fevereiro)
    nDay := Min(nDay, nMaxDay)

    // Formato canônico StoD: YYYYMMDD
    dResult := StoD(StrZero(nYear, 4) + StrZero(nMonth, 2) + StrZero(nDay, 2))

Return dResult

/*--------------------------------------------------------------------*
| ExportToCSV — Exporta consulta SQL para arquivo CSV via TCQuery
*---------------------------------------------------------------------*/
User Function ExportToCSV(cQuery, cFile)

    Local cLine   := ""
    Local nHandle := 0
    Local cAlias  := GetNextAlias()
    Local nI      := 0

    Default cFile := "/tmp/export_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + ".csv"

    nHandle := fCreate(cFile)
    If nHandle == -1
        ConOut("[ExportCSV] Erro ao criar arquivo: " + cFile)
        Return .F.
    EndIf

    // Executa query de forma compativel com TopConnect
    TCQuery ChangeQuery(cQuery) New Alias (cAlias)

    // Cabecalho das colunas
    cLine := ""
    For nI := 1 To (cAlias)->(FCount())
        cLine += (cAlias)->(FieldName(nI)) + ";"
    Next nI
    fWrite(nHandle, cLine + Chr(13) + Chr(10))

    // Registros
    While !(cAlias)->(Eof())
        cLine := ""
        For nI := 1 To (cAlias)->(FCount())
            cLine += cValToChar((cAlias)->(FieldGet(nI))) + ";"
        Next nI
        fWrite(nHandle, cLine + Chr(13) + Chr(10))
        (cAlias)->(DbSkip())
    EndDo

    fClose(nHandle)
    (cAlias)->(DbCloseArea())

    ConOut("[ExportCSV] Arquivo gerado com sucesso: " + cFile)

Return .T.

/*--------------------------------------------------------------------*
| SafeExec — Try-catch padrao para ADVPL com ErrorBlock
*---------------------------------------------------------------------*/
User Function SafeExec(bBlock, cErrorMsg)

    Local xResult := Nil
    Local bError  := ErrorBlock({|e| Break(e)})

    Default cErrorMsg := "Erro na execucao"

    Begin Sequence
        xResult := Eval(bBlock)
    Recover Using oError
        ConOut("[SafeExec] " + cErrorMsg + ": " + oError:Description)
        xResult := Nil
    End Sequence

    ErrorBlock(bError)

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
| ArrayContains — Verifica se array contem determinado valor
*---------------------------------------------------------------------*/
User Function ArrayContains(aArray, xValue)
Return (aScan(aArray, {|x| x == xValue}) > 0)
