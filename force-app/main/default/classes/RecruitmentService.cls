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
          throw new RecruitmentServiceException('Employer IDs cannot be null.');
        
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
        
        if (startDate == null || endDate == null) {
            return 0;
        }

       
        Date firstDate = startDate < endDate
            ? startDate : endDate;

        Date lastDate = startDate > endDate
            ? startDate : endDate;

        
        Date fromDate = firstDate.addDays(1);
        Date toDate = lastDate.addDays(-1);

        if (fromDate > toDate) {
            return 0;
        }

        
        Integer totalDays = fromDate.daysBetween(toDate) + 1;

     
        Integer fullWeeks = totalDays / 7;
        Integer workingDays = fullWeeks * 5;

      
        Integer remainingDays = Math.mod(totalDays, 7);

        
        Date weekStart = fromDate.toStartOfWeek();

        for (Integer i = 0; i < remainingDays; i++) {
            Date currentDate = weekStart.addDays(
                fromDate.daysBetween(weekStart) * -1 + i
            );

            Integer dayNumber = Math.mod(
                Date.newInstance(1900, 1, 7)
                    .daysBetween(currentDate),
                7
            );

           
            if (dayNumber != 0 && dayNumber != 6) {
                workingDays++;
            }
        }

      
        Set<Date> holidays = new Set<Date>();

        for (Holiday h : [
            SELECT ActivityDate
            FROM Holiday
            WHERE ActivityDate >= :fromDate
            AND ActivityDate <= :toDate
        ]) {
            holidays.add(h.ActivityDate);
        }

   
        for (Date holidayDate : holidays) {
            Integer dayNumber = Math.mod(
                Date.newInstance(1900, 1, 7)
                    .daysBetween(holidayDate),
                7
            );

            if (dayNumber != 0 && dayNumber != 6) {
                workingDays--;
            }
        }

        return workingDays;
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