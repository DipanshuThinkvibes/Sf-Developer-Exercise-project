public with sharing class RecruitmentService {
public class RecruitmentServiceException extends Exception {}

private static Map<String, List<String>> cachedOrgObjects;
//Get Consultant Name for a given Null parameter
public static List<String> getConsultantNames(){
    throw new RecruitmentServiceException('Consultant names cannot be retrieved for a null employer ID.');
    
}
//Get Consultant Names for a given Employer Ids
public static List<String> getConsultantNames(Id employerId) {
    if (employerId == null || employerId.getSObjectType() != Account.SObjectType) {
        throw new RecruitmentServiceException('Employer Id must be a non-empty Account Id.');
    }
    if ([SELECT COUNT() FROM Account WHERE Id = :employerId] == 0) {
        throw new RecruitmentServiceException('Employer not found.');
    }
   

    List<String> consultantsList = new List<String>();
    for (Hiring__c hiring : [ SELECT Consultant__r.Name FROM Hiring__c  WHERE Employer__c = :employerId  AND Consultant__c != NULL])
    {
        consultantsList.add(hiring.Consultant__r.Name);
    }
    return consultantsList;
}
 //Get Consultant BY Employer for Null Parameter
    public static Map<Id, Set<Id>> getConsultantsByEmployer() {
       Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
      
        for (Hiring__c h : [SELECT Employer__c, Consultant__c FROM Hiring__c WHERE Consultant__c != null AND Employer__c != null]) {
            if (!result.containsKey(h.Employer__c)) {
                result.put(h.Employer__c, new Set<Id>());
            }
            
            result.get(h.Employer__c).add(h.Consultant__c);
        }
        return result;
    }
//Get Consultant BY Employer for employer IDs
public static Map<Id, Set<Id>> getConsultantsByEmployer(Set<Id> employerIds) {
    Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
    if (employerIds != null && employerIds.isEmpty()) {
        return result;
    }

    String soql = 'SELECT Employer__c, Consultant__c FROM Hiring__c WHERE Consultant__c != null';
    if (employerIds != null) {
        soql += ' AND Employer__c IN :employerIds';
    }

    for (Hiring__c h : Database.query(soql)) {
        if (!result.containsKey(h.Employer__c)) {
            result.put(h.Employer__c, new Set<Id>());
        }
        result.put(h.Employer__c, result.get(h.Employer__c));
        result.get(h.Employer__c).add(h.Consultant__c);
    }
    return result;
}
//Count Working Days between two dates excluding weekends and holidays
public static Integer countWorkingDays(Date startDate,Date endDate) {
    Integer totalDays=startDate.daysBetween(endDate)-1;
    Integer remainingDays=Math.mod(totalDays,7);
    Integer weekdays=(totalDays/7)*5;
    for(Integer i=1;i<=remainingDays;i++){
        Integer dayNumber = Math.mod(Math.mod(Date.valueOf('1990-01-07').daysBetween(startDate.addDays(i)), 7) + 7,7);
        if(dayNumber!=0 && dayNumber!=6)
            weekdays++;
    }
    Set<Date> holidays = new Set<Date>();
    Date fromDate = startDate.addDays(1);
    Date toDate = endDate.addDays(-1);
    for (Holiday h : [SELECT ActivityDate FROM Holiday WHERE ActivityDate >= :fromDate AND ActivityDate <= :toDate]) {
        holidays.add(h.ActivityDate);
    }
    for (Date holidayDate : holidays) {
        Integer dayNumber = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(holidayDate),7);
        if (dayNumber != 0 && dayNumber != 6) {
            weekdays--;
        }
    }
    return weekdays;
}


//Get List of Standard and Custom Objects in the Org
public static Map<String, List<String>> listOrgObjects() {
    if (cachedOrgObjects != null) {
        return cachedOrgObjects;
    }
    List<String> standardObjects = new List<String>();
    List<String> customObjects = new List<String>();
    Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    for (String name : gd.keySet()) {
        Schema.DescribeSObjectResult d = gd.get(name).getDescribe();
        String labelName = d.getName();
        if (d.isCustom()) {
            customObjects.add(labelName);
        } else {
            standardObjects.add(labelName);
        }
    }
    standardObjects.sort();
    customObjects.sort();
    cachedOrgObjects = new Map<String, List<String>>{
        'standard' => standardObjects,
        'custom' => customObjects
    };
    return cachedOrgObjects;
}
}