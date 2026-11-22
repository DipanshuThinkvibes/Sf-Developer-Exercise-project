@IsTest
private class RecruitmentServiceTest {

  
    // TEST DATA CREATION METHODS
  

    private static Account createEmployer(String employerName) {
        Account employer = new Account(
            Name = employerName
        );
        insert employer;
        return employer;
    }

    private static Consultant__c createConsultant(
        String firstName,
        String lastName
    ) {
        Consultant__c consultant = new Consultant__c(
            Name = firstName + ' ' + lastName,
            First_Name__c = firstName,
            Last_Name__c = lastName
        );

        insert consultant;
        return consultant;
    }

    private static Hiring__c createHiring(
        Id employerId,
        Id consultantId
    ) {
        Hiring__c hiring = new Hiring__c(
            Employer__c = employerId,
            Consultant__c = consultantId,
            Hire_Date__c = Date.today()
        );

        insert hiring;
        return hiring;
    }


  
    // 1. GET CONSULTANT NAMES
  

    @IsTest
    static void testGetConsultantNamesWithoutParameter() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            RecruitmentService.getConsultantNames();
        } catch (
            RecruitmentService.RecruitmentServiceException e
        ) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Calling without Employer Id should throw an exception.'
        );
    }


    @IsTest
    static void testGetConsultantNamesWithValidEmployer() {

        Account employer = createEmployer('Test Employer');

        Consultant__c consultant1 =
            createConsultant('Rahul', 'Sharma');

        Consultant__c consultant2 =
            createConsultant('Neha', 'Gupta');

        createHiring(employer.Id, consultant1.Id);
        createHiring(employer.Id, consultant2.Id);

        Test.startTest();

        List<String> consultantNames =
            RecruitmentService.getConsultantNames(employer.Id);

        Test.stopTest();

        System.assertEquals(
            2,
            consultantNames.size(),
            'Two consultant names should be returned.'
        );

        System.assert(
            consultantNames.contains(consultant1.Name),
            'Rahul should be present.'
        );

        System.assert(
            consultantNames.contains(consultant2.Name),
            'Neha should be present.'
        );
    }


    @IsTest
    static void testGetConsultantNamesWithInvalidId() {

        Boolean exceptionThrown = false;

        try {
            RecruitmentService.getConsultantNames(
                UserInfo.getUserId()
            );
        } catch (
            RecruitmentService.RecruitmentServiceException e
        ) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'A User Id should not be accepted as an Employer Id.'
        );
    }


    @IsTest
    static void testGetConsultantNamesWithNullId() {

        Boolean exceptionThrown = false;

        try {
            RecruitmentService.getConsultantNames((Id)null);
        } catch (
            RecruitmentService.RecruitmentServiceException e
        ) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Null Employer Id should throw an exception.'
        );
    }


    @IsTest
    static void testGetConsultantNamesEmployerNotFound() {

        Account employer = createEmployer('Deleted Employer');

        Id deletedEmployerId = employer.Id;

        delete employer;

        Boolean exceptionThrown = false;

        try {
            RecruitmentService.getConsultantNames(
                deletedEmployerId
            );
        } catch (
            RecruitmentService.RecruitmentServiceException e
        ) {
            exceptionThrown = true;
        }

        System.assertEquals(
            true,
            exceptionThrown,
            'Deleted Employer should throw Employer not found.'
        );
    }


    @IsTest
    static void testGetConsultantNamesWithNoHiringRecords() {

        Account employer = createEmployer('Employer Without Hiring');

        Test.startTest();

        List<String> consultantNames =
            RecruitmentService.getConsultantNames(employer.Id);

        Test.stopTest();

        System.assertEquals(
            0,
            consultantNames.size(),
            'Employer without Hiring records should return an empty list.'
        );
    }


  
    // 2. GET CONSULTANTS BY EMPLOYER
  


    @IsTest
    static void testGetConsultantsByEmployerWithoutParameter() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {
            RecruitmentService.getConsultantsByEmployer();
        } catch (
            RecruitmentService.RecruitmentServiceException e
        ) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Calling without Employer IDs should throw an exception.'
        );
    }


    @IsTest
    static void testGetConsultantsByEmployerWithNullParameter() {

        Account employer1 = createEmployer('Employer A');
        Account employer2 = createEmployer('Employer B');

        Consultant__c consultant1 =
            createConsultant('Rahul', 'Sharma');

        Consultant__c consultant2 =
            createConsultant('Neha', 'Gupta');

        createHiring(employer1.Id, consultant1.Id);
        createHiring(employer2.Id, consultant2.Id);

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(
                (Set<Id>)null
            );

        Test.stopTest();

        System.assertEquals(
            2,
            result.size(),
            'Null Set should return consultants for all Employers.'
        );

        System.assertEquals(
            true,
            result.containsKey(employer1.Id)
        );

        System.assertEquals(
            true,
            result.containsKey(employer2.Id)
        );

        System.assertEquals(
            true,
            result.get(employer1.Id).contains(consultant1.Id)
        );

        System.assertEquals(
            true,
            result.get(employer2.Id).contains(consultant2.Id)
        );
    }


    @IsTest
    static void testGetConsultantsByEmployerWithSpecificIds() {

        Account employer1 = createEmployer('Employer A');
        Account employer2 = createEmployer('Employer B');

        Consultant__c consultant1 =
            createConsultant('Rahul', 'Sharma');

        Consultant__c consultant2 =
            createConsultant('Neha', 'Gupta');

        createHiring(employer1.Id, consultant1.Id);
        createHiring(employer2.Id, consultant2.Id);

        Set<Id> employerIds = new Set<Id>{
            employer1.Id
        };

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(
                employerIds
            );

        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'Only the requested Employer should be returned.'
        );

        System.assertEquals(
            true,
            result.containsKey(employer1.Id)
        );

        System.assertEquals(
            false,
            result.containsKey(employer2.Id)
        );

        System.assertEquals(
            true,
            result.get(employer1.Id).contains(consultant1.Id)
        );
    }


    @IsTest
    static void testGetConsultantsByEmployerWithEmptySet() {

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(
                new Set<Id>()
            );

        Test.stopTest();

        System.assertEquals(
            0,
            result.size(),
            'Empty Employer Id set should return an empty map.'
        );
    }


    @IsTest
    static void testGetConsultantsByEmployerWithMultipleConsultants() {

        Account employer = createEmployer('Employer A');

        Consultant__c consultant1 =
            createConsultant('Rahul', 'Sharma');

        Consultant__c consultant2 =
            createConsultant('Neha', 'Gupta');

        createHiring(employer.Id, consultant1.Id);
        createHiring(employer.Id, consultant2.Id);

        Test.startTest();

        Map<Id, Set<Id>> result =
            RecruitmentService.getConsultantsByEmployer(
                new Set<Id>{ employer.Id }
            );

        Test.stopTest();

        System.assertEquals(
            1,
            result.size()
        );

        System.assertEquals(
            2,
            result.get(employer.Id).size(),
            'Both consultants should be present.'
        );

        System.assert(
            result.get(employer.Id).contains(consultant1.Id)
        );

        System.assert(
            result.get(employer.Id).contains(consultant2.Id)
        );
    }


  
    // 3. COUNT WORKING DAYS
  


    @IsTest
    static void testCountWorkingDaysWithNullDates() {

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(
                null,
                Date.today()
            );

        Test.stopTest();

        System.assertEquals(
            0,
            result,
            'Null dates should return zero.'
        );
    }


    @IsTest
    static void testCountWorkingDaysWithSameDate() {

        Date testDate = Date.newInstance(2026, 11, 2);

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(
                testDate,
                testDate
            );

        Test.stopTest();

        System.assertEquals(
            0,
            result,
            'Same start and end dates should return zero.'
        );
    }


    @IsTest
    static void testCountWorkingDaysBetweenWeekdays() {

        // Monday to Friday.
        // The method excludes both start and end dates.
        // Tuesday, Wednesday and Thursday = 3 working days.

        Date startDate = Date.newInstance(2026, 11, 2);
        Date endDate = Date.newInstance(2026, 11, 6);

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(
                startDate,
                endDate
            );

        Test.stopTest();

        System.assertEquals(
            3,
            result,
            'Should count Tuesday, Wednesday and Thursday.'
        );
    }


    @IsTest
    static void testCountWorkingDaysWithReverseDates() {

        Date startDate = Date.newInstance(2026, 11, 2);
        Date endDate = Date.newInstance(2026, 11, 6);

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(
                endDate,
                startDate
            );

        Test.stopTest();

        System.assertEquals(
            3,
            result,
            'Reverse date order should give the same result.'
        );
    }


    @IsTest
    static void testCountWorkingDaysExcludingHoliday() {

        Date startDate = Date.newInstance(2026, 11, 2);
        Date endDate = Date.newInstance(2026, 11, 6);

        Date holidayDate = Date.newInstance(2026, 11, 4);

        Holiday testHoliday = new Holiday(
            Name = 'Test Holiday',
            ActivityDate = holidayDate,
            IsAllDay = true
        );

        insert testHoliday;

        Test.startTest();

        Integer result =
            RecruitmentService.countWorkingDays(
                startDate,
                endDate
            );

        Test.stopTest();

        System.assertEquals(
            2,
            result,
            'Wednesday holiday should be excluded from working days.'
        );
    }


  
    // 4. LIST ORG OBJECTS
  


    @IsTest
    static void testListOrgObjects() {

        Test.startTest();

        Map<String, List<String>> result =
            RecruitmentService.listOrgObjects();

        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'Object map should not be null.'
        );

        System.assertEquals(
            true,
            result.containsKey('standard')
        );

        System.assertEquals(
            true,
            result.containsKey('custom')
        );

        System.assert(
            result.get('standard').contains('Account'),
            'Account should be included in standard objects.'
        );

        System.assert(
            result.get('custom').contains('Consultant__c'),
            'Consultant__c should be included in custom objects.'
        );

        System.assert(
            result.get('custom').contains('Hiring__c'),
            'Hiring__c should be included in custom objects.'
        );
    }


    @IsTest
    static void testListOrgObjectsCaching() {

        Map<String, List<String>> firstResult =
            RecruitmentService.listOrgObjects();

        Map<String, List<String>> secondResult =
            RecruitmentService.listOrgObjects();

        System.assertEquals(
            firstResult,
            secondResult,
            'Cached object map should return the same values.'
        );
    }
}