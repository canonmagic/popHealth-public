class Practice
  include Mongoid::Document

  field :name, type: String
  field :organization, type: String
  field :address, type: String
  field :provider_id, type: BSON::ObjectId
  
  validates_presence_of :name, :organization
  validates :name, uniqueness: true
  belongs_to :provider, dependent: :destroy, optional: true
  has_many :users
  has_many :cqmPatient, class_name: 'CQM::Patient'

  def providers
    Provider.all({"parent_ids" => self.provider_id })
  end
end

=begin
[
  {
    _id: ObjectId("658076ba3e9e16e1d7e77f0b"),
    measure_relevance_hash: {
      '6552db7f3e9e16c5049adc40': { IPP: true, DENOM: true, DENEX: true }
    },
    code_description_hash: {
      '2:2_16_840_1_113883_3_221_5': 'MEDICAID',
      '99213:2_16_840_1_113883_6_12': 'Office or other outpatient visit for the evaluation and management of an established patient, which requires a medically appropriate history and/or examination and low level of medical decision making. When using time for code selection, 20-29 minutes of total time is spent on the date of the encounter.',
      '32485007:2_16_840_1_113883_6_96': 'Hospital admission (procedure)',
      '428371000124100:2_16_840_1_113883_6_96': 'Discharge to healthcare facility for hospice care (procedure)',
      '21112-8:2_16_840_1_113883_6_1': 'Birth date',
      'F:2_16_840_1_113883_5_1': 'Female',
      '2106-3:2_16_840_1_113883_6_238': 'White',
      '2135-2:2_16_840_1_113883_6_238': 'Hispanic or Latino'
    },
    reported_measure_hqmf_ids: [],
    _type: 'CQM::Patient',
    addresses: [
      {
        _id: ObjectId("658076ba3e9e16e1d7e77f04"),
        street: [ '76367 Wendell Forge Motorway' ],
        use: 'HP',
        city: 'Jamaalport',
        state: 'NM',
        zip: '88044',
        country: 'US'
      }
    ],
    telecoms: [
      {
        _id: ObjectId("658076ba3e9e16e1d7e77f0c"),
        value: 'tel:(304)608-7943',
        use: 'HP'
      },
      {
        _id: ObjectId("658076ba3e9e16e1d7e77f0d"),
        value: 'mailto:apowers7015@example.com',
        use: 'HP'
      }
    ],
    givenNames: [ 'Amanda' ],
    familyName: 'Powers',
    medical_record_number: '6552c86fdfe4bd0fc574b6e8',
    bundleId: '6552d8c73e9e16c5049963fc',
    provider_ids: [ ObjectId("658076ba3e9e16e1d7e77f05") ],
    qdmPatient: {
      _id: ObjectId("658076ba3e9e16e1d7e77f0e"),
      qdmVersion: '5.6',
      birthDatetime: ISODate("1967-06-13T13:30:00.000Z"),
      extendedData: {
        provider_performances: [
          '[{"_id":"658076ba3e9e16e1d7e77f0a","end_date":null,"provider_id":"658076ba3e9e16e1d7e77f05","start_date":null}]'
        ]
      },
      dataElements: [
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f00"),
          dataElementCodes: [
            {
              code: '2',
              system: '2.16.840.1.113883.3.221.5',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          qdmTitle: 'Patient Characteristic Payer',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.58',
          qdmCategory: 'patient_characteristic',
          qdmStatus: 'payer',
          qdmVersion: '5.6',
          _type: 'QDM::PatientCharacteristicPayer',
          relevantPeriod: {
            low: ISODate("1995-12-30T00:00:00.000Z"),
            high: null,
            lowClosed: true,
            highClosed: true,
            _type: 'QDM::Interval'
          }
        },
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f01"),
          dataElementCodes: [
            {
              code: '99213',
              system: '2.16.840.1.113883.6.12',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          facilityLocations: [],
          qdmTitle: 'Encounter, Performed',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.5',
          qdmCategory: 'encounter',
          qdmStatus: 'performed',
          qdmVersion: '5.6',
          _type: 'QDM::EncounterPerformed',
          authorDatetime: null,
          relevantPeriod: {
            low: ISODate("2021-03-11T08:00:00.000Z"),
            high: ISODate("2021-03-11T09:00:00.000Z"),
            lowClosed: true,
            highClosed: true,
            _type: 'QDM::Interval'
          },
          admissionSource: null,
          dischargeDisposition: null,
          clazz: null,
          diagnoses: null,
          lengthOfStay: { value: 0, unit: 'd', _type: 'QDM::Quantity' },
          relatedTo: []
        },
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f02"),
          dataElementCodes: [
            {
              code: '32485007',
              system: '2.16.840.1.113883.6.96',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          facilityLocations: [],
          qdmTitle: 'Encounter, Performed',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.5',
          qdmCategory: 'encounter',
          qdmStatus: 'performed',
          qdmVersion: '5.6',
          _type: 'QDM::EncounterPerformed',
          authorDatetime: null,
          relevantPeriod: {
            low: ISODate("2021-08-12T08:00:00.000Z"),
            high: ISODate("2021-08-24T08:15:00.000Z"),
            lowClosed: true,
            highClosed: true,
            _type: 'QDM::Interval'
          },
          admissionSource: null,
          dischargeDisposition: {
            code: '428371000124100',
            system: '2.16.840.1.113883.6.96',
            display: null,
            version: null,
            _type: 'QDM::Code'
          },
          clazz: null,
          diagnoses: null,
          lengthOfStay: { value: 12, unit: 'd', _type: 'QDM::Quantity' },
          relatedTo: []
        },
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f0f"),
          dataElementCodes: [
            {
              code: '21112-8',
              system: '2.16.840.1.113883.6.1',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          qdmTitle: 'Patient Characteristic Birthdate',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.54',
          qdmCategory: 'patient_characteristic',
          qdmStatus: 'birthdate',
          qdmVersion: '5.6',
          _type: 'QDM::PatientCharacteristicBirthdate',
          birthDatetime: ISODate("1967-06-13T13:30:00.000Z")
        },
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f10"),
          dataElementCodes: [
            {
              code: 'F',
              system: '2.16.840.1.113883.5.1',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          qdmTitle: 'Patient Characteristic Sex',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.55',
          qdmCategory: 'patient_characteristic',
          qdmStatus: 'gender',
          qdmVersion: '5.6',
          _type: 'QDM::PatientCharacteristicSex'
        },
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f11"),
          dataElementCodes: [
            {
              code: '2106-3',
              system: '2.16.840.1.113883.6.238',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          qdmTitle: 'Patient Characteristic Race',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.59',
          qdmCategory: 'patient_characteristic',
          qdmStatus: 'race',
          qdmVersion: '5.6',
          _type: 'QDM::PatientCharacteristicRace'
        },
        {
          _id: ObjectId("658076ba3e9e16e1d7e77f12"),
          dataElementCodes: [
            {
              code: '2135-2',
              system: '2.16.840.1.113883.6.238',
              display: null,
              version: null,
              _type: 'QDM::Code'
            }
          ],
          qdmTitle: 'Patient Characteristic Ethnicity',
          hqmfOid: '2.16.840.1.113883.10.20.28.4.56',
          qdmCategory: 'patient_characteristic',
          qdmStatus: 'ethnicity',
          qdmVersion: '5.6',
          _type: 'QDM::PatientCharacteristicEthnicity'
        }
      ]
    }
  }
]

=end